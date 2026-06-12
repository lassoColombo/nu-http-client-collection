# Auto-generated client for DataLakeAnalyticsAccountManagementClient v2016-11-01
# Source: https://api.apis.guru/v2/specs/azure.com/datalake-analytics-account/2016-11-01/swagger.json
# Auth: --token flag or $env.DATALAKEANALYTICSACCOUNTMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATALAKEANALYTICSACCOUNTMANAGEMENTCLIENT_TOKEN | default "" }
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
def type-completer [] { ["Microsoft.DataLakeAnalytics/accounts"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-data-lake-analytics-operations List" } } | get name | first)
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

# Lists all of the available Data Lake Analytics REST API operations.
#
# GET /providers/Microsoft.DataLakeAnalytics/operations
# operationId: Operations_List
export def "providers-microsoft-data-lake-analytics-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DataLakeAnalytics/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the first page of Data Lake Analytics accounts, if any, within the current subscription. This includes a link to the next page, if any.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DataLakeAnalytics/accounts
# operationId: Accounts_List
export def "subscriptions-providers-microsoft-data-lake-analytics-accounts List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataLakeAnalytics/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets subscription-level properties and limits for Data Lake Analytics specified by resource location.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DataLakeAnalytics/locations/{location}/capability
# operationId: Locations_GetCapability
export def "subscriptions-providers-microsoft-data-lake-analytics-locations-capability GetCapability" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<accountCount: int, maxAccountCount: int, migrationState: bool, state: string, subscriptionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataLakeAnalytics/locations/($location)/capability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the specified account name is available or taken.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataLakeAnalytics/locations/{location}/checkNameAvailability
# operationId: Accounts_CheckNameAvailability
export def "subscriptions-providers-microsoft-data-lake-analytics-locations-check-name-availability CheckNameAvailability" [
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
  --api-version: string # Client Api Version.
  name: string # The Data Lake Analytics name to check availability for.
  type: string@type-completer # The resource type. Note: This should not be set by the user, as the constant value is Microsoft.DataLakeAnalytics/accounts
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataLakeAnalytics/locations/($location)/checkNameAvailability" $qp)
  let body = {name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the first page of Data Lake Analytics accounts, if any, within a specific resource group. This includes a link to the next page, if any.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts
# operationId: Accounts_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts ListByResourceGroup" [
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
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Begins the delete process for the Data Lake Analytics account object specified by the account name.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}
# operationId: Accounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts Delete" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets details of the specified Data Lake Analytics account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}
# operationId: Accounts_Get
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts Get" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<computePolicies: list<record>, currentTier: string, dataLakeStoreAccounts: list<record>, defaultDataLakeStoreAccount: string, firewallAllowAzureIps: string, firewallRules: list<record>, firewallState: string, maxDegreeOfParallelism: int, maxDegreeOfParallelismPerJob: int, maxJobCount: int, minPriorityPerJob: int, newTier: string, queryStoreRetention: int, storageAccounts: list<record>, systemMaxDegreeOfParallelism: int, systemMaxJobCount: int, accountId: string, creationTime: string, endpoint: string, lastModifiedTime: string, provisioningState: string, state: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Data Lake Analytics account object specified by the accountName with the contents of the account object.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}
# operationId: Accounts_Update
# --properties shape: {computePolicies?: list, dataLakeStoreAccounts?: list, firewallAllowAzureIps?: "Enabled"|"Disabled", firewallRules?: list, firewallState?: "Enabled"|"Disabled", maxDegreeOfParallelism?: int, maxDegreeOfParallelismPerJob?: int, maxJobCount?: int, minPriorityPerJob?: int, newTier?: "Consumption"|"Commitment_100AUHours"|"Commitment_500AUHours"|"Commitment_1000AUHours"|"Commitment_5000AUHours"|"Commitment_10000AUHours"|"Commitment_50000AUHours"|"Commitment_100000AUHours"|"Commitment_500000AUHours", queryStoreRetention?: int, storageAccounts?: list}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts Update" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The properties to update that are associated with an underlying Data Lake Analytics account. — shape: {computePolicies?: list, dataLakeStoreAccounts?: list, firewallAllowAzureIps?: "Enabled"|"Disabled", firewallRules?: list, firewallState?: "Enabled"|"Disabled", maxDegreeOfParallelism?: int, maxDegreeOfParallelismPerJob?: int, maxJobCount?: int, minPriorityPerJob?: int, newTier?: "Consumption"|"Commitment_100AUHours"|"Commitment_500AUHours"|"Commitment_1000AUHours"|"Commitment_5000AUHours"|"Commitment_10000AUHours"|"Commitment_50000AUHours"|"Commitment_100000AUHours"|"Commitment_500000AUHours", queryStoreRetention?: int, storageAccounts?: list}
  --tags: record # The resource tags.
]: any -> record<properties: record<computePolicies: list<record>, currentTier: string, dataLakeStoreAccounts: list<record>, defaultDataLakeStoreAccount: string, firewallAllowAzureIps: string, firewallRules: list<record>, firewallState: string, maxDegreeOfParallelism: int, maxDegreeOfParallelismPerJob: int, maxJobCount: int, minPriorityPerJob: int, newTier: string, queryStoreRetention: int, storageAccounts: list<record>, systemMaxDegreeOfParallelism: int, systemMaxJobCount: int, accountId: string, creationTime: string, endpoint: string, lastModifiedTime: string, provisioningState: string, state: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates the specified Data Lake Analytics account. This supplies the user with computation services for Data Lake Analytics workloads.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}
# operationId: Accounts_Create
# --properties shape: {computePolicies?: list, dataLakeStoreAccounts: list, defaultDataLakeStoreAccount: string, firewallAllowAzureIps?: "Enabled"|"Disabled", firewallRules?: list, firewallState?: "Enabled"|"Disabled", maxDegreeOfParallelism?: int, maxDegreeOfParallelismPerJob?: int, maxJobCount?: int, minPriorityPerJob?: int, newTier?: "Consumption"|"Commitment_100AUHours"|"Commitment_500AUHours"|"Commitment_1000AUHours"|"Commitment_5000AUHours"|"Commitment_10000AUHours"|"Commitment_50000AUHours"|"Commitment_100000AUHours"|"Commitment_500000AUHours", queryStoreRetention?: int, storageAccounts?: list}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts Create" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  location: string # The resource location.
  properties: any # shape: {computePolicies?: list, dataLakeStoreAccounts: list, defaultDataLakeStoreAccount: string, firewallAllowAzureIps?: "Enabled"|"Disabled", firewallRules?: list, firewallState?: "Enabled"|"Disabled", maxDegreeOfParallelism?: int, maxDegreeOfParallelismPerJob?: int, maxJobCount?: int, minPriorityPerJob?: int, newTier?: "Consumption"|"Commitment_100AUHours"|"Commitment_500AUHours"|"Commitment_1000AUHours"|"Commitment_5000AUHours"|"Commitment_10000AUHours"|"Commitment_50000AUHours"|"Commitment_100000AUHours"|"Commitment_500000AUHours", queryStoreRetention?: int, storageAccounts?: list}
  --tags: record # The resource tags.
]: any -> record<properties: record<computePolicies: list<record>, currentTier: string, dataLakeStoreAccounts: list<record>, defaultDataLakeStoreAccount: string, firewallAllowAzureIps: string, firewallRules: list<record>, firewallState: string, maxDegreeOfParallelism: int, maxDegreeOfParallelismPerJob: int, maxJobCount: int, minPriorityPerJob: int, newTier: string, queryStoreRetention: int, storageAccounts: list<record>, systemMaxDegreeOfParallelism: int, systemMaxJobCount: int, accountId: string, creationTime: string, endpoint: string, lastModifiedTime: string, provisioningState: string, state: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)" $qp)
  let body = {location: $location, properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Data Lake Analytics compute policies within the specified Data Lake Analytics account. An account supports, at most, 50 policies
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/computePolicies
# operationId: ComputePolicies_ListByAccount
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-compute-policies ListByAccount" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/computePolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified compute policy from the specified Data Lake Analytics account
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/computePolicies/{computePolicyName}
# operationId: ComputePolicies_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-compute-policies Delete" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  computePolicyName: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/computePolicies/($computePolicyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified Data Lake Analytics compute policy.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/computePolicies/{computePolicyName}
# operationId: ComputePolicies_Get
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-compute-policies Get" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  computePolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<maxDegreeOfParallelismPerJob: int, minPriorityPerJob: int, objectId: string, objectType: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/computePolicies/($computePolicyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified compute policy.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/computePolicies/{computePolicyName}
# operationId: ComputePolicies_Update
# --properties shape: {maxDegreeOfParallelismPerJob?: int, minPriorityPerJob?: int, objectId?: string, objectType?: "User"|"Group"|"ServicePrincipal"}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-compute-policies Update" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  computePolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The compute policy properties to use when updating a compute policy. — shape: {maxDegreeOfParallelismPerJob?: int, minPriorityPerJob?: int, objectId?: string, objectType?: "User"|"Group"|"ServicePrincipal"}
]: any -> record<properties: record<maxDegreeOfParallelismPerJob: int, minPriorityPerJob: int, objectId: string, objectType: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/computePolicies/($computePolicyName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates the specified compute policy. During update, the compute policy with the specified name will be replaced with this new compute policy. An account supports, at most, 50 policies
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/computePolicies/{computePolicyName}
# operationId: ComputePolicies_CreateOrUpdate
# --properties shape: {maxDegreeOfParallelismPerJob?: int, minPriorityPerJob?: int, objectId: string, objectType: "User"|"Group"|"ServicePrincipal"}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-compute-policies CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  computePolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: any # The compute policy properties to use when creating a new compute policy. — shape: {maxDegreeOfParallelismPerJob?: int, minPriorityPerJob?: int, objectId: string, objectType: "User"|"Group"|"ServicePrincipal"}
]: any -> record<properties: record<maxDegreeOfParallelismPerJob: int, minPriorityPerJob: int, objectId: string, objectType: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/computePolicies/($computePolicyName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the first page of Data Lake Store accounts linked to the specified Data Lake Analytics account. The response includes a link to the next page, if any.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/dataLakeStoreAccounts
# operationId: DataLakeStoreAccounts_ListByAccount
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-data-lake-store-accounts ListByAccount" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/dataLakeStoreAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Data Lake Analytics account specified to remove the specified Data Lake Store account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/dataLakeStoreAccounts/{dataLakeStoreAccountName}
# operationId: DataLakeStoreAccounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-data-lake-store-accounts Delete" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  dataLakeStoreAccountName: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/dataLakeStoreAccounts/($dataLakeStoreAccountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified Data Lake Store account details in the specified Data Lake Analytics account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/dataLakeStoreAccounts/{dataLakeStoreAccountName}
# operationId: DataLakeStoreAccounts_Get
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-data-lake-store-accounts Get" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  dataLakeStoreAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<suffix: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/dataLakeStoreAccounts/($dataLakeStoreAccountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified Data Lake Analytics account to include the additional Data Lake Store account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/dataLakeStoreAccounts/{dataLakeStoreAccountName}
# operationId: DataLakeStoreAccounts_Add
# --properties shape: {suffix?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-data-lake-store-accounts Add" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  dataLakeStoreAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The Data Lake Store account properties to use when adding a new Data Lake Store account. — shape: {suffix?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/dataLakeStoreAccounts/($dataLakeStoreAccountName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Data Lake Analytics firewall rules within the specified Data Lake Analytics account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/firewallRules
# operationId: FirewallRules_ListByAccount
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-firewall-rules ListByAccount" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/firewallRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified firewall rule from the specified Data Lake Analytics account
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/firewallRules/{firewallRuleName}
# operationId: FirewallRules_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-firewall-rules Delete" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  firewallRuleName: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/firewallRules/($firewallRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified Data Lake Analytics firewall rule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/firewallRules/{firewallRuleName}
# operationId: FirewallRules_Get
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-firewall-rules Get" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  firewallRuleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<endIpAddress: string, startIpAddress: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/firewallRules/($firewallRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified firewall rule.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/firewallRules/{firewallRuleName}
# operationId: FirewallRules_Update
# --properties shape: {endIpAddress?: string, startIpAddress?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-firewall-rules Update" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  firewallRuleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The firewall rule properties to use when updating a firewall rule. — shape: {endIpAddress?: string, startIpAddress?: string}
]: any -> record<properties: record<endIpAddress: string, startIpAddress: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/firewallRules/($firewallRuleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates the specified firewall rule. During update, the firewall rule with the specified name will be replaced with this new firewall rule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/firewallRules/{firewallRuleName}
# operationId: FirewallRules_CreateOrUpdate
# --properties shape: {endIpAddress: string, startIpAddress: string}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-firewall-rules CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  firewallRuleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: any # The firewall rule properties to use when creating a new firewall rule. — shape: {endIpAddress: string, startIpAddress: string}
]: any -> record<properties: record<endIpAddress: string, startIpAddress: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/firewallRules/($firewallRuleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the first page of Azure Storage accounts, if any, linked to the specified Data Lake Analytics account. The response includes a link to the next page, if any.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts
# operationId: StorageAccounts_ListByAccount
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts ListByAccount" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the specified Data Lake Analytics account to remove an Azure Storage account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts/{storageAccountName}
# operationId: StorageAccounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts Delete" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  storageAccountName: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts/($storageAccountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified Azure Storage account linked to the given Data Lake Analytics account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts/{storageAccountName}
# operationId: StorageAccounts_Get
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts Get" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  storageAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<suffix: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts/($storageAccountName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Data Lake Analytics account to replace Azure Storage blob account details, such as the access key and/or suffix.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts/{storageAccountName}
# operationId: StorageAccounts_Update
# --properties shape: {accessKey?: string, suffix?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts Update" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  storageAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The Azure Storage account properties to use when updating an Azure Storage account. — shape: {accessKey?: string, suffix?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts/($storageAccountName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the specified Data Lake Analytics account to add an Azure Storage account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts/{storageAccountName}
# operationId: StorageAccounts_Add
# --properties shape: {accessKey: string, suffix?: string}
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts Add" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  storageAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: any # The Azure Storage account properties to use when adding a new Azure Storage account. — shape: {accessKey: string, suffix?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts/($storageAccountName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Azure Storage containers, if any, associated with the specified Data Lake Analytics and Azure Storage account combination. The response includes a link to the next page of results, if any.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts/{storageAccountName}/containers
# operationId: StorageAccounts_ListStorageContainers
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts-containers ListStorageContainers" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  storageAccountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts/($storageAccountName)/containers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified Azure Storage container associated with the given Data Lake Analytics and Azure Storage accounts.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts/{storageAccountName}/containers/{containerName}
# operationId: StorageAccounts_GetStorageContainer
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts-containers GetStorageContainer" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  storageAccountName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<lastModifiedTime: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts/($storageAccountName)/containers/($containerName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the SAS token associated with the specified Data Lake Analytics and Azure Storage account and container combination.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataLakeAnalytics/accounts/{accountName}/storageAccounts/{storageAccountName}/containers/{containerName}/listSasTokens
# operationId: StorageAccounts_ListSasTokens
export def "subscriptions-resource-groups-providers-microsoft-data-lake-analytics-accounts-storage-accounts-containers-list-sas-tokens ListSasTokens" [
  subscriptionId: string
  resourceGroupName: string
  accountName: string
  storageAccountName: string
  containerName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<accessToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataLakeAnalytics/accounts/($accountName)/storageAccounts/($storageAccountName)/containers/($containerName)/listSasTokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
