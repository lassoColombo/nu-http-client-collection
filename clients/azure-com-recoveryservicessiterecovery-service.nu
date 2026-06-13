# Auto-generated client for SiteRecoveryManagementClient v2018-07-10
# Source: https://api.apis.guru/v2/specs/azure.com/recoveryservicessiterecovery-service/2018-07-10/swagger.json
# Auth: --token flag or $env.SITERECOVERYMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SITERECOVERYMANAGEMENTCLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-compute-virtual-machines-providers-microsoft-recovery-services-replication-eligibility-results List" } } | get name | first)
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

# Gets the validation errors in case the VM is unsuitable for protection.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults
# operationId: ReplicationEligibilityResults_List
export def "subscriptions-resource-groups-providers-microsoft-compute-virtual-machines-providers-microsoft-recovery-services-replication-eligibility-results List" [
  resourceGroupName: string
  subscriptionId: string
  virtualMachineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Compute/virtualMachines/($virtualMachineName)/providers/Microsoft.RecoveryServices/replicationEligibilityResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the validation errors in case the VM is unsuitable for protection.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults/default
# operationId: ReplicationEligibilityResults_Get
export def "subscriptions-resource-groups-providers-microsoft-compute-virtual-machines-providers-microsoft-recovery-services-replication-eligibility-results-default Get" [
  resourceGroupName: string
  subscriptionId: string
  virtualMachineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<clientRequestId: string, errors: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Compute/virtualMachines/($virtualMachineName)/providers/Microsoft.RecoveryServices/replicationEligibilityResults/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of available operations.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/operations
# operationId: Operations_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-operations List" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of configured email notification(alert) configurations.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings
# operationId: ReplicationAlertSettings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-alert-settings List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationAlertSettings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an email notification(alert) configuration.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}
# operationId: ReplicationAlertSettings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-alert-settings Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  alertSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationAlertSettings/($alertSettingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configures email notifications for this vault.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}
# operationId: ReplicationAlertSettings_Create
# --properties shape: {customEmailAddresses?: list, locale?: string, sendToOwners?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-alert-settings Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  alertSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Properties of a configure alert request. — shape: {customEmailAddresses?: list, locale?: string, sendToOwners?: string}
]: any -> record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationAlertSettings/($alertSettingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of Azure Site Recovery events.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents
# operationId: ReplicationEvents_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-events List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the details of an Azure Site recovery event.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents/{eventName}
# operationId: ReplicationEvents_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-events Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  eventName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<affectedObjectFriendlyName: string, description: string, eventCode: string, eventSpecificDetails: record<instanceType: string>, eventType: string, fabricId: string, healthErrors: list<record>, providerSpecificDetails: record<instanceType: string>, severity: string, timeOfOccurrence: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationEvents/($eventName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of ASR fabrics
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics
# operationId: ReplicationFabrics_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purges the site.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# operationId: ReplicationFabrics_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics Purge" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of an ASR fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# operationId: ReplicationFabrics_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an Azure Site Recovery fabric.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# operationId: ReplicationFabrics_Create
# --properties shape: {customDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Properties of site details provided during the time of site creation — shape: {customDetails?: record}
]: any -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Checks the consistency of the ASR fabric.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/checkConsistency
# operationId: ReplicationFabrics_CheckConsistency
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-check-consistency CheckConsistency" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/checkConsistency" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Migrates the site to AAD.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/migratetoaad
# operationId: ReplicationFabrics_MigrateToAad
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-migratetoaad MigrateToAad" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/migratetoaad" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Perform failover of the process server.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/reassociateGateway
# operationId: ReplicationFabrics_ReassociateGateway
# --properties shape: {containerName?: string, sourceProcessServerId?: string, targetProcessServerId?: string, updateType?: string, vmsToMigrate?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-reassociate-gateway ReassociateGateway" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of the Failover Process Server request. — shape: {containerName?: string, sourceProcessServerId?: string, targetProcessServerId?: string, updateType?: string, vmsToMigrate?: list}
]: any -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/reassociateGateway" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the site.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/remove
# operationId: ReplicationFabrics_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-remove Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Renews certificate for the fabric.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/renewCertificate
# operationId: ReplicationFabrics_RenewCertificate
# --properties shape: {renewCertificateType?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-renew-certificate RenewCertificate" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Renew Certificate input properties. — shape: {renewCertificateType?: string}
]: any -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/renewCertificate" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of logical networks under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks
# operationId: ReplicationLogicalNetworks_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-logical-networks ListByReplicationFabrics" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationLogicalNetworks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a logical network with specified server id and logical network name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks/{logicalNetworkName}
# operationId: ReplicationLogicalNetworks_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-logical-networks Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  logicalNetworkName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<friendlyName: string, logicalNetworkDefinitionsStatus: string, logicalNetworkUsage: string, networkVirtualizationStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationLogicalNetworks/($logicalNetworkName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of networks under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks
# operationId: ReplicationNetworks_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks ListByReplicationFabrics" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationNetworks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a network with specified server id and network name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}
# operationId: ReplicationNetworks_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  networkName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<fabricType: string, friendlyName: string, networkType: string, subnets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationNetworks/($networkName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the network mappings under a network.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings
# operationId: ReplicationNetworkMappings_ListByReplicationNetworks
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings ListByReplicationNetworks" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  networkName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationNetworks/($networkName)/replicationNetworkMappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete network mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  networkName: string
  networkMappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationNetworks/($networkName)/replicationNetworkMappings/($networkMappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets network mapping by name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  networkName: string
  networkMappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationNetworks/($networkName)/replicationNetworkMappings/($networkMappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates network mapping.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Update
# --properties shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings Update" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  networkName: string
  networkMappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Common input details for network mapping operation. — shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
]: any -> record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationNetworks/($networkName)/replicationNetworkMappings/($networkMappingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates network mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Create
# --properties shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  networkName: string
  networkMappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Common input details for network mapping operation. — shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
]: any -> record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationNetworks/($networkName)/replicationNetworkMappings/($networkMappingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of protection container for a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers
# operationId: ReplicationProtectionContainers_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers ListByReplicationFabrics" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the protection container details.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}
# operationId: ReplicationProtectionContainers_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a protection container.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}
# operationId: ReplicationProtectionContainers_Create
# --properties shape: {providerSpecificInput?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Create protection container input properties. — shape: {providerSpecificInput?: list}
]: any -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a protectable item to the replication protection container.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/discoverProtectableItem
# operationId: ReplicationProtectionContainers_DiscoverProtectableItem
# --properties shape: {friendlyName?: string, ipAddress?: string, osType?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-discover-protectable-item DiscoverProtectableItem" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Discover protectable item properties. — shape: {friendlyName?: string, ipAddress?: string, osType?: string}
]: any -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/discoverProtectableItem" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a protection container.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/remove
# operationId: ReplicationProtectionContainers_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-remove Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of migration items in the protection container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems
# operationId: ReplicationMigrationItems_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items ListByReplicationProtectionContainers" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the migration item.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --deleteOption: string # The delete option.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "deleteOption" $deleteOption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates migration item.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Update
# --properties shape: {providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items Update" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Update migration item input properties. — shape: {providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enables migration.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Create
# --properties shape: {policyId: string, providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Enable migration input properties. — shape: {policyId: string, providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Migrate item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrate
# operationId: ReplicationMigrationItems_Migrate
# --properties shape: {providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-migrate Migrate" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Migrate input properties. — shape: {providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)/migrate" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the recovery points for a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints
# operationId: MigrationRecoveryPoints_ListByReplicationMigrationItems
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-migration-recovery-points ListByReplicationMigrationItems" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)/migrationRecoveryPoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a recovery point for a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints/{migrationRecoveryPointName}
# operationId: MigrationRecoveryPoints_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-migration-recovery-points Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  migrationRecoveryPointName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<recoveryPointTime: string, recoveryPointType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)/migrationRecoveryPoints/($migrationRecoveryPointName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test migrate item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrate
# operationId: ReplicationMigrationItems_TestMigrate
# --properties shape: {providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-test-migrate TestMigrate" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Test migrate input properties. — shape: {providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)/testMigrate" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Test migrate cleanup.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrateCleanup
# operationId: ReplicationMigrationItems_TestMigrateCleanup
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-test-migrate-cleanup TestMigrateCleanup" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  migrationItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Test migrate cleanup input properties. — shape: {comments?: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationMigrationItems/($migrationItemName)/testMigrateCleanup" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of protectable items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems
# operationId: ReplicationProtectableItems_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protectable-items ListByReplicationProtectionContainers" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectableItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a protectable item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems/{protectableItemName}
# operationId: ReplicationProtectableItems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protectable-items Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  protectableItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<customDetails: record<instanceType: string>, friendlyName: string, protectionReadinessErrors: list<string>, protectionStatus: string, recoveryServicesProviderId: string, replicationProtectedItemId: string, supportedReplicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectableItems/($protectableItemName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of Replication protected items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems
# operationId: ReplicationProtectedItems_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items ListByReplicationProtectionContainers" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purges protection.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items Purge" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a Replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates protection.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Update
# --properties shape: {enableRdpOnTargetOption?: string, licenseType?: "NotSpecified"|"NoLicenseType"|"WindowsServer", providerSpecificDetails?: record, recoveryAvailabilitySetId?: string, recoveryAzureVMName?: string, recoveryAzureVMSize?: string, selectedRecoveryAzureNetworkId?: string, selectedSourceNicId?: string, selectedTfoAzureNetworkId?: string, vmNics?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items Update" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Update protected item input properties. — shape: {enableRdpOnTargetOption?: string, licenseType?: "NotSpecified"|"NoLicenseType"|"WindowsServer", providerSpecificDetails?: record, recoveryAvailabilitySetId?: string, recoveryAzureVMName?: string, recoveryAzureVMSize?: string, selectedRecoveryAzureNetworkId?: string, selectedSourceNicId?: string, selectedTfoAzureNetworkId?: string, vmNics?: list}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enables protection.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Create
# --properties shape: {policyId?: string, protectableItemId?: string, providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Enable protection input properties. — shape: {policyId?: string, protectableItemId?: string, providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resolve health errors.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/ResolveHealthErrors
# operationId: ReplicationProtectedItems_ResolveHealthErrors
# --properties shape: {healthErrors?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-resolve-health-errors ResolveHealthErrors" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Resolve health input properties. — shape: {healthErrors?: list}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/ResolveHealthErrors" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add disk(s) for protection.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/addDisks
# operationId: ReplicationProtectedItems_AddDisks
# --properties shape: {providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-add-disks AddDisks" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Add Disks input properties. — shape: {providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/addDisks" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change or apply recovery point.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/applyRecoveryPoint
# operationId: ReplicationProtectedItems_ApplyRecoveryPoint
# --properties shape: {providerSpecificDetails?: record, recoveryPointId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-apply-recovery-point ApplyRecoveryPoint" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input properties to apply recovery point. — shape: {providerSpecificDetails?: record, recoveryPointId?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/applyRecoveryPoint" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute commit failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/failoverCommit
# operationId: ReplicationProtectedItems_FailoverCommit
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-failover-commit FailoverCommit" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/failoverCommit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute planned failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/plannedFailover
# operationId: ReplicationProtectedItems_PlannedFailover
# --properties shape: {failoverDirection?: string, providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-planned-failover PlannedFailover" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/plannedFailover" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute Reverse Replication\Reprotect
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/reProtect
# operationId: ReplicationProtectedItems_Reprotect
# --properties shape: {failoverDirection?: string, providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-re-protect Reprotect" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Reverse replication input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/reProtect" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get recovery points for a replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints
# operationId: RecoveryPoints_ListByReplicationProtectedItems
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-recovery-points ListByReplicationProtectedItems" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/recoveryPoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a recovery point.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints/{recoveryPointName}
# operationId: RecoveryPoints_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-recovery-points Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  recoveryPointName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<providerSpecificDetails: record<instanceType: string>, recoveryPointTime: string, recoveryPointType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/recoveryPoints/($recoveryPointName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disables protection.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/remove
# operationId: ReplicationProtectedItems_Delete
# --properties shape: {disableProtectionReason?: "NotSpecified"|"MigrationComplete", replicationProviderInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-remove Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Disable protection input properties. — shape: {disableProtectionReason?: "NotSpecified"|"MigrationComplete", replicationProviderInput?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/remove" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes disk(s).
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/removeDisks
# operationId: ReplicationProtectedItems_RemoveDisks
# --properties shape: {providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-remove-disks RemoveDisks" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Remove Disk input properties. — shape: {providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/removeDisks" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resynchronize or repair replication.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/repairReplication
# operationId: ReplicationProtectedItems_RepairReplication
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-repair-replication RepairReplication" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/repairReplication" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of target compute sizes for the replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/targetComputeSizes
# operationId: TargetComputeSizes_ListByReplicationProtectedItems
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-target-compute-sizes ListByReplicationProtectedItems" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/targetComputeSizes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute test failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailover
# operationId: ReplicationProtectedItems_TestFailover
# --properties shape: {failoverDirection?: string, networkId?: string, networkType?: string, providerSpecificDetails?: record, skipTestFailoverCleanup?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-test-failover TestFailover" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, networkId?: string, networkType?: string, providerSpecificDetails?: record, skipTestFailoverCleanup?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/testFailover" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute test failover cleanup.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailoverCleanup
# operationId: ReplicationProtectedItems_TestFailoverCleanup
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-test-failover-cleanup TestFailoverCleanup" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Input definition for test failover cleanup input properties. — shape: {comments?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/testFailoverCleanup" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute unplanned failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/unplannedFailover
# operationId: ReplicationProtectedItems_UnplannedFailover
# --properties shape: {failoverDirection?: string, providerSpecificDetails?: record, sourceSiteOperations?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-unplanned-failover UnplannedFailover" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicatedProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record, sourceSiteOperations?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicatedProtectedItemName)/unplannedFailover" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the mobility service on a protected item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicationProtectedItemName}/updateMobilityService
# operationId: ReplicationProtectedItems_UpdateMobilityService
# --properties shape: {runAsAccountId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-update-mobility-service UpdateMobilityService" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  replicationProtectedItemName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of an update mobility service request. — shape: {runAsAccountId?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectedItems/($replicationProtectedItemName)/updateMobilityService" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of protection container mappings for a protection container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings
# operationId: ReplicationProtectionContainerMappings_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings ListByReplicationProtectionContainers" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectionContainerMappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purge protection container mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings Purge" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  mappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectionContainerMappings/($mappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a protection container mapping/
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  mappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectionContainerMappings/($mappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update protection container mapping.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Update
# --properties shape: {providerSpecificInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings Update" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  mappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Container pairing update input. — shape: {providerSpecificInput?: record}
]: any -> record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectionContainerMappings/($mappingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create protection container mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Create
# --properties shape: {policyId?: string, providerSpecificInput?: record, targetProtectionContainerId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  mappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Configure pairing input properties. — shape: {policyId?: string, providerSpecificInput?: record, targetProtectionContainerId?: string}
]: any -> record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectionContainerMappings/($mappingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove protection container mapping.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}/remove
# operationId: ReplicationProtectionContainerMappings_Delete
# --properties shape: {providerSpecificInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings-remove Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  mappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Unpairing input properties. — shape: {providerSpecificInput?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/replicationProtectionContainerMappings/($mappingName)/remove" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Switches protection from one container to another or one replication provider to another.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/switchprotection
# operationId: ReplicationProtectionContainers_SwitchProtection
# --properties shape: {providerSpecificDetails?: record, replicationProtectedItemName?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-switchprotection SwitchProtection" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  protectionContainerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Switch protection input properties. — shape: {providerSpecificDetails?: record, replicationProtectedItemName?: string}
]: any -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationProtectionContainers/($protectionContainerName)/switchprotection" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of registered recovery services providers for the fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders
# operationId: ReplicationRecoveryServicesProviders_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers ListByReplicationFabrics" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationRecoveryServicesProviders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purges recovery service provider from fabric
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# operationId: ReplicationRecoveryServicesProviders_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers Purge" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  providerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationRecoveryServicesProviders/($providerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a recovery services provider.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# operationId: ReplicationRecoveryServicesProviders_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  providerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationRecoveryServicesProviders/($providerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a recovery services provider.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# operationId: ReplicationRecoveryServicesProviders_Create
# --properties shape: {authenticationIdentityInput: record, machineName: string, resourceAccessIdentityInput: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  providerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # The properties of an add provider request. — shape: {authenticationIdentityInput: record, machineName: string, resourceAccessIdentityInput: record}
]: any -> record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationRecoveryServicesProviders/($providerName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh details from the recovery services provider.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/refreshProvider
# operationId: ReplicationRecoveryServicesProviders_RefreshProvider
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers-refresh-provider RefreshProvider" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  providerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationRecoveryServicesProviders/($providerName)/refreshProvider" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes provider from fabric. Note: Deleting provider for any fabric other than SingleHost is unsupported. To maintain backward compatibility for released clients the object "deleteRspInput" is used (if the object is empty we assume that it is old client and continue the old behavior).
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/remove
# operationId: ReplicationRecoveryServicesProviders_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers-remove Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  providerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationRecoveryServicesProviders/($providerName)/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of storage classification objects under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications
# operationId: ReplicationStorageClassifications_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications ListByReplicationFabrics" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationStorageClassifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a storage classification.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}
# operationId: ReplicationStorageClassifications_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  storageClassificationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<friendlyName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationStorageClassifications/($storageClassificationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of storage classification mappings objects under a storage.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings
# operationId: ReplicationStorageClassificationMappings_ListByReplicationStorageClassifications
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings ListByReplicationStorageClassifications" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  storageClassificationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationStorageClassifications/($storageClassificationName)/replicationStorageClassificationMappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a storage classification mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# operationId: ReplicationStorageClassificationMappings_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  storageClassificationName: string
  storageClassificationMappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationStorageClassifications/($storageClassificationName)/replicationStorageClassificationMappings/($storageClassificationMappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a storage classification mapping.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# operationId: ReplicationStorageClassificationMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  storageClassificationName: string
  storageClassificationMappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<targetStorageClassificationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationStorageClassifications/($storageClassificationName)/replicationStorageClassificationMappings/($storageClassificationMappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create storage classification mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# operationId: ReplicationStorageClassificationMappings_Create
# --properties shape: {targetStorageClassificationId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  storageClassificationName: string
  storageClassificationMappingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Storage mapping input properties. — shape: {targetStorageClassificationId?: string}
]: any -> record<properties: record<targetStorageClassificationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationStorageClassifications/($storageClassificationName)/replicationStorageClassificationMappings/($storageClassificationMappingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of vCenter registered under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters
# operationId: ReplicationvCenters_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers ListByReplicationFabrics" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationvCenters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove vCenter operation.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  vCenterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationvCenters/($vCenterName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the details of a vCenter.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  vCenterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationvCenters/($vCenterName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update vCenter operation.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Update
# --properties shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers Update" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  vCenterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of an update vCenter request. — shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
]: any -> record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationvCenters/($vCenterName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add vCenter.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Create
# --properties shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  fabricName: string
  vCenterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of an add vCenter request. — shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
]: any -> record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationFabrics/($fabricName)/replicationvCenters/($vCenterName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of jobs.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs
# operationId: ReplicationJobs_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports the details of the Azure Site Recovery jobs of the vault.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/export
# operationId: ReplicationJobs_Export
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-export Export" [
  resourceName: string
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
  --api-version: string # Client Api Version.
  --affectedObjectTypes: string # The type of objects.
  --endTime: string # Date time to get jobs up to.
  --fabricId: string # The Id of the fabric to search jobs under.
  --jobStatus: string # The states of the job to be filtered can be in.
  --startTime: string # Date time to get jobs from.
]: any -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationJobs/export" $qp)
  let body = {affectedObjectTypes: $affectedObjectTypes, endTime: $endTime, fabricId: $fabricId, jobStatus: $jobStatus, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the job details.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}
# operationId: ReplicationJobs_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationJobs/($jobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancels the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/cancel
# operationId: ReplicationJobs_Cancel
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-cancel Cancel" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationJobs/($jobName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/restart
# operationId: ReplicationJobs_Restart
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-restart Restart" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationJobs/($jobName)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resumes the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/resume
# operationId: ReplicationJobs_Resume
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-resume Resume" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Resume job properties. — shape: {comments?: string}
]: any -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationJobs/($jobName)/resume" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of migration items in the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationMigrationItems
# operationId: ReplicationMigrationItems_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-migration-items List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
  --skipToken: string # The pagination token.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "skipToken" $skipToken "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationMigrationItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the network mappings under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworkMappings
# operationId: ReplicationNetworkMappings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-network-mappings List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationNetworkMappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of networks. View-only API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworks
# operationId: ReplicationNetworks_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-networks List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationNetworks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of replication policies
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies
# operationId: ReplicationPolicies_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationPolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the policy.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  policyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationPolicies/($policyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the requested policy.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  policyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationPolicies/($policyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the policy.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Update
# --properties shape: {replicationProviderSettings?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies Update" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  policyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Policy update properties. — shape: {replicationProviderSettings?: record}
]: any -> record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationPolicies/($policyName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates the policy.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Create
# --properties shape: {providerSpecificInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  policyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Policy creation properties. — shape: {providerSpecificInput?: record}
]: any -> record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationPolicies/($policyName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of replication protected items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectedItems
# operationId: ReplicationProtectedItems_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-protected-items List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
  --skipToken: string # The pagination token. Possible values: "FabricId" or "FabricId_CloudId" or null
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "skipToken" $skipToken "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationProtectedItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of all protection container mappings in a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainerMappings
# operationId: ReplicationProtectionContainerMappings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-protection-container-mappings List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationProtectionContainerMappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of all protection containers in a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainers
# operationId: ReplicationProtectionContainers_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-protection-containers List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationProtectionContainers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of recovery plans.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans
# operationId: ReplicationRecoveryPlans_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified recovery plan.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans Delete" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the requested recovery plan.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the given recovery plan.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Update
# --properties shape: {groups?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans Update" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Recovery plan update properties. — shape: {groups?: list}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a recovery plan with the given details.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Create
# --properties shape: {failoverDeploymentModel?: "NotApplicable"|"Classic"|"ResourceManager", groups: list, primaryFabricId: string, recoveryFabricId: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan creation properties. — shape: {failoverDeploymentModel?: "NotApplicable"|"Classic"|"ResourceManager", groups: list, primaryFabricId: string, recoveryFabricId: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute commit failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/failoverCommit
# operationId: ReplicationRecoveryPlans_FailoverCommit
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-failover-commit FailoverCommit" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)/failoverCommit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute planned failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/plannedFailover
# operationId: ReplicationRecoveryPlans_PlannedFailover
# --properties shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-planned-failover PlannedFailover" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan planned failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)/plannedFailover" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute reprotect of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/reProtect
# operationId: ReplicationRecoveryPlans_Reprotect
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-re-protect Reprotect" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)/reProtect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute test failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailover
# operationId: ReplicationRecoveryPlans_TestFailover
# --properties shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", networkId?: string, networkType: string, providerSpecificDetails?: list, skipTestFailoverCleanup?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-test-failover TestFailover" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan test failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", networkId?: string, networkType: string, providerSpecificDetails?: list, skipTestFailoverCleanup?: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)/testFailover" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute test failover cleanup of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailoverCleanup
# operationId: ReplicationRecoveryPlans_TestFailoverCleanup
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-test-failover-cleanup TestFailoverCleanup" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan test failover cleanup input properties. — shape: {comments?: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)/testFailoverCleanup" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute unplanned failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/unplannedFailover
# operationId: ReplicationRecoveryPlans_UnplannedFailover
# --properties shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list, sourceSiteOperations: "Required"|"NotRequired"}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-unplanned-failover UnplannedFailover" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  recoveryPlanName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan unplanned failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list, sourceSiteOperations: "Required"|"NotRequired"}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryPlans/($recoveryPlanName)/unplannedFailover" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of registered recovery services providers in the vault. This is a view only api.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryServicesProviders
# operationId: ReplicationRecoveryServicesProviders_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-services-providers List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationRecoveryServicesProviders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of storage classification mappings objects under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassificationMappings
# operationId: ReplicationStorageClassificationMappings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-storage-classification-mappings List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationStorageClassificationMappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of storage classification objects under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassifications
# operationId: ReplicationStorageClassifications_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-storage-classifications List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationStorageClassifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the data of supported OSes by SRS.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationSupportedOperatingSystems
# operationId: SupportedOperatingSystems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-supported-operating-systems Get" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<supportedOsList: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationSupportedOperatingSystems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the health summary for the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth
# operationId: ReplicationVaultHealth_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-health Get" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationVaultHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refreshes health summary of the vault.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth/default/refresh
# operationId: ReplicationVaultHealth_Refresh
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-health-default-refresh Refresh" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationVaultHealth/default/refresh" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of vault setting.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings
# operationId: ReplicationVaultSetting_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-settings List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationVaultSettings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the vault setting.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}
# operationId: ReplicationVaultSetting_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-settings Get" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  vaultSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<migrationSolutionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationVaultSettings/($vaultSettingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates vault setting. A vault setting object is a singleton per vault and it is always present by default.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}
# operationId: ReplicationVaultSetting_Create
# --properties shape: {migrationSolutionId: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-settings Create" [
  resourceName: string
  resourceGroupName: string
  subscriptionId: string
  vaultSettingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Input to create vault setting. — shape: {migrationSolutionId: string}
]: any -> record<properties: record<migrationSolutionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationVaultSettings/($vaultSettingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of vCenter registered under the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationvCenters
# operationId: ReplicationvCenters_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replicationv-centers List" [
  resourceName: string
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.RecoveryServices/vaults/($resourceName)/replicationvCenters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
