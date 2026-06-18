# Auto-generated client for BatchManagement v2019-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/batch-BatchManagement/2019-08-01/swagger.json
# Auth: --token flag or $env.BATCHMANAGEMENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BATCHMANAGEMENT_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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
def type-completer [] { ["Microsoft.Batch/batchAccounts"] }
def key-name-completer [] { ["Primary" "Secondary"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-batch-operations list" } } | get name | first)
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

# Lists available operations for the Microsoft.Batch provider
#
# GET /providers/Microsoft.Batch/operations
# operationId: Operations_List
export def "providers-microsoft-batch-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Batch/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the Batch accounts associated with the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Batch/batchAccounts
# operationId: BatchAccount_List
export def "subscriptions-providers-microsoft-batch-batch-accounts list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Batch/batchAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the Batch account name is available in the specified region.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Batch/locations/{locationName}/checkNameAvailability
# operationId: Location_CheckNameAvailability
export def "subscriptions-providers-microsoft-batch-locations-check-name-availability check" [
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
  --api-version: string # The API version to be used with the HTTP request.
  name: string # The name to check for availability
  type: string@type-completer # The resource type. Must be set to Microsoft.Batch/batchAccounts
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_name: (encode-path-segment $location_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Batch/locations/{location_name}/checkNameAvailability") $qp)
  let req_body = {"name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the Batch service quotas for the specified subscription at the given location.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Batch/locations/{locationName}/quotas
# operationId: Location_GetQuotas
export def "subscriptions-providers-microsoft-batch-locations-quotas get" [
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
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<accountQuota: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_name: (encode-path-segment $location_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Batch/locations/{location_name}/quotas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the Batch accounts associated with the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts
# operationId: BatchAccount_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts list" [
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
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified Batch account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# operationId: BatchAccount_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified Batch account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# operationId: BatchAccount_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the properties of an existing Batch account.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# operationId: BatchAccount_Update
# --properties shape: {autoStorage?: any}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --properties: any # The properties of a Batch account. — shape: {autoStorage?: any}
  --tags: record # The user-specified tags associated with the account.
]: any -> record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}") $qp)
  let req_body = {"properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Batch account with the specified parameters. Existing accounts cannot be updated with this API and should instead be updated with the Update Batch Account API.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}
# operationId: BatchAccount_Create
# --properties shape: {autoStorage?: any, keyVaultReference?: any, poolAllocationMode?: "BatchService"|"UserSubscription"}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  location: string # The region in which to create the account.
  --properties: any # The properties of a Batch account. — shape: {autoStorage?: any, keyVaultReference?: any, poolAllocationMode?: "BatchService"|"UserSubscription"}
  --tags: record # The user-specified tags associated with the account.
]: any -> record<properties: record<accountEndpoint: string, activeJobAndJobScheduleQuota: int, autoStorage: record<lastKeySync: string, storageAccountId: string>, dedicatedCoreQuota: int, dedicatedCoreQuotaPerVMFamily: list<record>, dedicatedCoreQuotaPerVMFamilyEnforced: bool, keyVaultReference: record<id: string, url: string>, lowPriorityCoreQuota: int, poolAllocationMode: string, poolQuota: int, provisioningState: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}") $qp)
  let req_body = {"location": $location, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all of the applications in the specified account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications
# operationId: Application_List
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an application.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# operationId: Application_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# operationId: Application_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates settings for the specified application.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# operationId: Application_Update
# --properties shape: {allowUpdates?: bool, defaultVersion?: string, displayName?: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --properties: any # The properties associated with the Application. — shape: {allowUpdates?: bool, defaultVersion?: string, displayName?: string}
]: any -> record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds an application to the specified Batch account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}
# operationId: Application_Create
# --properties shape: {allowUpdates?: bool, defaultVersion?: string, displayName?: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --properties: any # The properties associated with the Application. — shape: {allowUpdates?: bool, defaultVersion?: string, displayName?: string}
]: any -> record<properties: record<allowUpdates: bool, defaultVersion: string, displayName: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all of the application packages in the specified application.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions
# operationId: ApplicationPackage_List
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications-versions list-package" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an application package record and its associated binary file.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}
# operationId: ApplicationPackage_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications-versions delete-package" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name), version_name: (encode-path-segment $version_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}/versions/{version_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified application package.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}
# operationId: ApplicationPackage_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications-versions get-package" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name), version_name: (encode-path-segment $version_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}/versions/{version_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an application package record. The record contains the SAS where the package should be uploaded to. Once it is uploaded the `ApplicationPackage` needs to be activated using `ApplicationPackageActive` before it can be used.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}
# operationId: ApplicationPackage_Create
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications-versions create-package" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --properties: any # Properties of an application package
]: any -> record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name), version_name: (encode-path-segment $version_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}/versions/{version_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Activates the specified application package. This should be done after the `ApplicationPackage` was created and uploaded. This needs to be done before an `ApplicationPackage` can be used on Pools or Tasks
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/applications/{applicationName}/versions/{versionName}/activate
# operationId: ApplicationPackage_Activate
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-applications-versions-activate create-package" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  application_name: string
  version_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  format: string # The format of the application package binary file.
]: any -> record<properties: record<format: string, lastActivationTime: string, state: string, storageUrl: string, storageUrlExpiry: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), application_name: (encode-path-segment $application_name), version_name: (encode-path-segment $version_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/applications/{application_name}/versions/{version_name}/activate") $qp)
  let req_body = {"format": $format} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all of the certificates in the specified account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates
# operationId: Certificate_ListByBatchAccount
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-certificates list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --select: string # Comma separated list of properties that should be returned. e.g. "properties/provisioningState". Only top level properties under properties/ are valid for selection.
  --filter: string # OData filter expression. Valid properties for filtering are "properties/provisioningState", "properties/provisioningStateTransitionTime", "name".
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/certificates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified certificate.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# operationId: Certificate_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-certificates delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/certificates/{certificate_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified certificate.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# operationId: Certificate_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-certificates get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/certificates/{certificate_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the properties of an existing certificate.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# operationId: Certificate_Update
# --properties shape: {data: string, password?: string, format?: "Pfx"|"Cer", thumbprint?: string, thumbprintAlgorithm?: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-certificates update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --if-match: string # The entity state (ETag) version of the certificate to update. This value can be omitted or set to "*" to apply the operation unconditionally.
  --properties: any # Certificate properties for create operations — shape: {data: string, password?: string, format?: "Pfx"|"Cer", thumbprint?: string, thumbprintAlgorithm?: string}
]: any -> record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/certificates/{certificate_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new certificate inside the specified account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}
# operationId: Certificate_Create
# --properties shape: {data: string, password?: string, format?: "Pfx"|"Cer", thumbprint?: string, thumbprintAlgorithm?: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-certificates create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --if-match: string # The entity state (ETag) version of the certificate to update. A value of "*" can be used to apply the operation only if the certificate already exists. If omitted, this operation will always be applied.
  --if-none-match: string # Set to '*' to allow a new certificate to be created, but to prevent updating an existing certificate. Other values will be ignored.
  --properties: any # Certificate properties for create operations — shape: {data: string, password?: string, format?: "Pfx"|"Cer", thumbprint?: string, thumbprintAlgorithm?: string}
]: any -> record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/certificates/{certificate_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancels a failed deletion of a certificate from the specified account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/certificates/{certificateName}/cancelDelete
# operationId: Certificate_CancelDeletion
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-certificates-cancel-delete cancel-deletion" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<deleteCertificateError: record<code: string, details: list, message: string, target: string>, previousProvisioningState: string, previousProvisioningStateTransitionTime: string, provisioningState: string, provisioningStateTransitionTime: string, publicData: string, format: string, thumbprint: string, thumbprintAlgorithm: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/certificates/{certificate_name}/cancelDelete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the account keys for the specified Batch account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/listKeys
# operationId: BatchAccount_GetKeys
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-list-keys get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<accountName: string, primary: string, secondary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/listKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all of the pools in the specified account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools
# operationId: Pool_ListByBatchAccount
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-pools list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. (format: int32)
  --select: string # Comma separated list of properties that should be returned. e.g. "properties/provisioningState". Only top level properties under properties/ are valid for selection.
  --filter: string # OData filter expression. Valid properties for filtering are: name properties/allocationState properties/allocationStateTransitionTime properties/creationTime properties/provisioningState properties/provisioningStateTransitionTime properties/lastModified properties/vmSize properties/interNodeCommunication properties/scaleSettings/autoScale properties/scaleSettings/fixedScale
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/pools") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified pool.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# operationId: Pool_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-pools delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), pool_name: (encode-path-segment $pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/pools/{pool_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified pool.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# operationId: Pool_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-pools get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), pool_name: (encode-path-segment $pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/pools/{pool_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the properties of an existing pool.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# operationId: Pool_Update
# --properties shape: {applicationLicenses?: list<string>, applicationPackages?: list, autoScaleRun?: any, certificates?: list, deploymentConfiguration?: any, displayName?: string, interNodeCommunication?: "Enabled"|"Disabled", maxTasksPerNode?: int, metadata?: list, mountConfiguration?: list, networkConfiguration?: any, resizeOperationStatus?: any, scaleSettings?: any, startTask?: any, taskSchedulingPolicy?: any, userAccounts?: list, vmSize?: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-pools update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --if-match: string # The entity state (ETag) version of the pool to update. This value can be omitted or set to "*" to apply the operation unconditionally.
  --properties: any # Pool properties. — shape: {applicationLicenses?: list<string>, applicationPackages?: list, autoScaleRun?: any, certificates?: list, deploymentConfiguration?: any, displayName?: string, interNodeCommunication?: "Enabled"|"Disabled", maxTasksPerNode?: int, metadata?: list, mountConfiguration?: list, networkConfiguration?: any, resizeOperationStatus?: any, scaleSettings?: any, startTask?: any, taskSchedulingPolicy?: any, userAccounts?: list, vmSize?: string}
]: any -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), pool_name: (encode-path-segment $pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/pools/{pool_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new pool inside the specified account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}
# operationId: Pool_Create
# --properties shape: {applicationLicenses?: list<string>, applicationPackages?: list, autoScaleRun?: any, certificates?: list, deploymentConfiguration?: any, displayName?: string, interNodeCommunication?: "Enabled"|"Disabled", maxTasksPerNode?: int, metadata?: list, mountConfiguration?: list, networkConfiguration?: any, resizeOperationStatus?: any, scaleSettings?: any, startTask?: any, taskSchedulingPolicy?: any, userAccounts?: list, vmSize?: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-pools create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  --if-match: string # The entity state (ETag) version of the pool to update. A value of "*" can be used to apply the operation only if the pool already exists. If omitted, this operation will always be applied.
  --if-none-match: string # Set to '*' to allow a new pool to be created, but to prevent updating an existing pool. Other values will be ignored.
  --properties: any # Pool properties. — shape: {applicationLicenses?: list<string>, applicationPackages?: list, autoScaleRun?: any, certificates?: list, deploymentConfiguration?: any, displayName?: string, interNodeCommunication?: "Enabled"|"Disabled", maxTasksPerNode?: int, metadata?: list, mountConfiguration?: list, networkConfiguration?: any, resizeOperationStatus?: any, scaleSettings?: any, startTask?: any, taskSchedulingPolicy?: any, userAccounts?: list, vmSize?: string}
]: any -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), pool_name: (encode-path-segment $pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/pools/{pool_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disables automatic scaling for a pool.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}/disableAutoScale
# operationId: Pool_DisableAutoScale
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-pools-disable-auto-scale disable" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), pool_name: (encode-path-segment $pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/pools/{pool_name}/disableAutoScale") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stops an ongoing resize operation on the pool.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/pools/{poolName}/stopResize
# operationId: Pool_StopResize
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-pools-stop-resize stop" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, applicationLicenses: list<string>, applicationPackages: list<record>, autoScaleRun: record<error: record, evaluationTime: string, results: string>, certificates: list<record>, creationTime: string, currentDedicatedNodes: int, currentLowPriorityNodes: int, deploymentConfiguration: record<cloudServiceConfiguration: record, virtualMachineConfiguration: record>, displayName: string, interNodeCommunication: string, lastModified: string, maxTasksPerNode: int, metadata: list<record>, mountConfiguration: list<record>, networkConfiguration: record<endpointConfiguration: record, publicIPs: list, subnetId: string>, provisioningState: string, provisioningStateTransitionTime: string, resizeOperationStatus: record<errors: list, nodeDeallocationOption: string, resizeTimeout: string, startTime: string, targetDedicatedNodes: int, targetLowPriorityNodes: int>, scaleSettings: record<autoScale: record, fixedScale: record>, startTask: record<commandLine: string, containerSettings: record, environmentSettings: list, maxTaskRetryCount: int, resourceFiles: list, userIdentity: record, waitForSuccess: bool>, taskSchedulingPolicy: record<nodeFillType: string>, userAccounts: list<record>, vmSize: string>, etag: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name), pool_name: (encode-path-segment $pool_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/pools/{pool_name}/stopResize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerates the specified account key for the Batch account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/regenerateKeys
# operationId: BatchAccount_RegenerateKey
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-regenerate-keys create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
  key_name: string@key-name-completer # The type of account key to regenerate.
]: any -> record<accountName: string, primary: string, secondary: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/regenerateKeys") $qp)
  let req_body = {"keyName": $key_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Synchronizes access keys for the auto-storage account configured for the specified Batch account.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Batch/batchAccounts/{accountName}/syncAutoStorageKeys
# operationId: BatchAccount_SynchronizeAutoStorageKeys
export def "subscriptions-resource-groups-providers-microsoft-batch-batch-accounts-sync-auto-storage-keys create-synchronize" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to be used with the HTTP request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), account_name: (encode-path-segment $account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Batch/batchAccounts/{account_name}/syncAutoStorageKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
