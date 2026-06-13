# Auto-generated client for StorageManagementClient v2015-12-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/azsadmin-farms/2015-12-01-preview/swagger.json
# Auth: --token flag or $env.STORAGEMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://adminmanagement.local.azurestack.external"
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

def base-url-completer [] { ["https://adminmanagement.local.azurestack.external"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms List" } } | get name | first)
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

# Returns a list of all storage farms.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms
# operationId: Farms_List
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms List" [
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
  --api-version: string # REST Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the Storage properties and settings for a specified storage farm.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms/{farmId}
# operationId: Farms_Get
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms Get" [
  subscriptionId: string
  resourceGroupName: string
  farmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # REST Api Version.
]: nothing -> record<properties: record<farmId: string, settings: record<bandwidthThrottleIsEnabled: bool, corsAllowedOriginsList: string, dataCenterUriHostSuffixes: string, defaultEgressThresholdInGbps: float, defaultIngressThresholdInGbps: float, defaultIntranetEgressThresholdInGbps: float, defaultIntranetIngressThresholdInGbps: float, defaultRequestThresholdInTps: float, defaultThrottleProbabilityDecayIntervalInSeconds: int, defaultTotalEgressThresholdInGbps: float, defaultTotalIngressThresholdInGbps: float, feedbackRefreshIntervalInSeconds: int, gracePeriodForFullThrottlingInRefreshIntervals: int, gracePeriodMaxThrottleProbability: float, hostStyleHttpPort: int, hostStyleHttpsPort: int, minimumEgressThresholdInGbps: float, minimumIngressThresholdInGbps: float, minimumIntranetEgressThresholdInGbps: float, minimumIntranetIngressThresholdInGbps: float, minimumRequestThresholdInTps: float, minimumTotalEgressThresholdInGbps: float, minimumTotalIngressThresholdInGbps: float, numberOfAccountsToSync: int, overallEgressThresholdInGbps: float, overallIngressThresholdInGbps: float, overallIntranetEgressThresholdInGbps: float, overallIntranetIngressThresholdInGbps: float, overallRequestThresholdInTps: float, overallTotalEgressThresholdInGbps: float, overallTotalIngressThresholdInGbps: float, retentionPeriodForDeletedStorageAccountsInDays: int, settingsPollingIntervalInSecond: int, toleranceFactorForEgress: float, toleranceFactorForIngress: float, toleranceFactorForIntranetEgress: float, toleranceFactorForIntranetIngress: float, toleranceFactorForTotalEgress: float, toleranceFactorForTotalIngress: float, toleranceFactorForTps: float, usageCollectionIntervalInSeconds: int>, settingsStore: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms/($farmId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing storage farm.
#
# PATCH /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms/{farmId}
# operationId: Farms_Update
# --properties shape: {farmId?: string, settings?: record, settingsStore?: string, version?: string}
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms Update" [
  subscriptionId: string
  resourceGroupName: string
  farmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # REST Api Version.
  --properties: record # The properties of storage farm. — shape: {farmId?: string, settings?: record, settingsStore?: string, version?: string}
  --id: string # Resource ID.
  --location: string # Resource location.
  --name: string # Resource Name.
  --tags: record # Resource tags.
  --type: string # Resource type.
]: any -> record<properties: record<farmId: string, settings: record<bandwidthThrottleIsEnabled: bool, corsAllowedOriginsList: string, dataCenterUriHostSuffixes: string, defaultEgressThresholdInGbps: float, defaultIngressThresholdInGbps: float, defaultIntranetEgressThresholdInGbps: float, defaultIntranetIngressThresholdInGbps: float, defaultRequestThresholdInTps: float, defaultThrottleProbabilityDecayIntervalInSeconds: int, defaultTotalEgressThresholdInGbps: float, defaultTotalIngressThresholdInGbps: float, feedbackRefreshIntervalInSeconds: int, gracePeriodForFullThrottlingInRefreshIntervals: int, gracePeriodMaxThrottleProbability: float, hostStyleHttpPort: int, hostStyleHttpsPort: int, minimumEgressThresholdInGbps: float, minimumIngressThresholdInGbps: float, minimumIntranetEgressThresholdInGbps: float, minimumIntranetIngressThresholdInGbps: float, minimumRequestThresholdInTps: float, minimumTotalEgressThresholdInGbps: float, minimumTotalIngressThresholdInGbps: float, numberOfAccountsToSync: int, overallEgressThresholdInGbps: float, overallIngressThresholdInGbps: float, overallIntranetEgressThresholdInGbps: float, overallIntranetIngressThresholdInGbps: float, overallRequestThresholdInTps: float, overallTotalEgressThresholdInGbps: float, overallTotalIngressThresholdInGbps: float, retentionPeriodForDeletedStorageAccountsInDays: int, settingsPollingIntervalInSecond: int, toleranceFactorForEgress: float, toleranceFactorForIngress: float, toleranceFactorForIntranetEgress: float, toleranceFactorForIntranetIngress: float, toleranceFactorForTotalEgress: float, toleranceFactorForTotalIngress: float, toleranceFactorForTps: float, usageCollectionIntervalInSeconds: int>, settingsStore: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms/($farmId)" $qp)
  let body = {properties: $properties, id: $id, location: $location, name: $name, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new storage farm.
#
# PUT /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms/{farmId}
# operationId: Farms_Create
# --properties shape: {settingAccessString?: string}
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms Create" [
  subscriptionId: string
  resourceGroupName: string
  farmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # REST Api Version.
  --properties: record # Setting access string. — shape: {settingAccessString?: string}
  --id: string # Resource ID.
  --location: string # Resource location.
  --name: string # Resource Name.
  --tags: record # Resource tags.
  --type: string # Resource type.
]: any -> record<properties: record<farmId: string, settings: record<bandwidthThrottleIsEnabled: bool, corsAllowedOriginsList: string, dataCenterUriHostSuffixes: string, defaultEgressThresholdInGbps: float, defaultIngressThresholdInGbps: float, defaultIntranetEgressThresholdInGbps: float, defaultIntranetIngressThresholdInGbps: float, defaultRequestThresholdInTps: float, defaultThrottleProbabilityDecayIntervalInSeconds: int, defaultTotalEgressThresholdInGbps: float, defaultTotalIngressThresholdInGbps: float, feedbackRefreshIntervalInSeconds: int, gracePeriodForFullThrottlingInRefreshIntervals: int, gracePeriodMaxThrottleProbability: float, hostStyleHttpPort: int, hostStyleHttpsPort: int, minimumEgressThresholdInGbps: float, minimumIngressThresholdInGbps: float, minimumIntranetEgressThresholdInGbps: float, minimumIntranetIngressThresholdInGbps: float, minimumRequestThresholdInTps: float, minimumTotalEgressThresholdInGbps: float, minimumTotalIngressThresholdInGbps: float, numberOfAccountsToSync: int, overallEgressThresholdInGbps: float, overallIngressThresholdInGbps: float, overallIntranetEgressThresholdInGbps: float, overallIntranetIngressThresholdInGbps: float, overallRequestThresholdInTps: float, overallTotalEgressThresholdInGbps: float, overallTotalIngressThresholdInGbps: float, retentionPeriodForDeletedStorageAccountsInDays: int, settingsPollingIntervalInSecond: int, toleranceFactorForEgress: float, toleranceFactorForIngress: float, toleranceFactorForIntranetEgress: float, toleranceFactorForIntranetIngress: float, toleranceFactorForTotalEgress: float, toleranceFactorForTotalIngress: float, toleranceFactorForTps: float, usageCollectionIntervalInSeconds: int>, settingsStore: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms/($farmId)" $qp)
  let body = {properties: $properties, id: $id, location: $location, name: $name, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of metric definitions for a storage farm.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms/{farmId}/metricdefinitions
# operationId: Farms_ListMetricDefinitions
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms-metricdefinitions ListMetricDefinitions" [
  subscriptionId: string
  resourceGroupName: string
  farmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # REST Api Version.
]: nothing -> record<nextLink: string, value: table<metricAvailabilities: list, name: record, primaryAggregationType: string, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms/($farmId)/metricdefinitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of storage farm metrics.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms/{farmId}/metrics
# operationId: Farms_ListMetrics
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms-metrics ListMetrics" [
  subscriptionId: string
  resourceGroupName: string
  farmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # REST Api Version.
]: nothing -> record<nextLink: string, value: table<endTime: string, metricUnit: string, metricValues: list, name: record, startTime: string, timeGrain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms/($farmId)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start garbage collection on deleted storage objects.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms/{farmId}/ondemandgc
# operationId: Farms_StartGarbageCollection
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms-ondemandgc StartGarbageCollection" [
  subscriptionId: string
  resourceGroupName: string
  farmId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # REST Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms/($farmId)/ondemandgc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the state of the garbage collection job.
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Storage.Admin/farms/{farmId}/operationresults/{operationId}
# operationId: Farms_GetGarbageCollectionState
export def "subscriptions-resourcegroups-providers-microsoft-storage-admin-farms-operationresults GetGarbageCollectionState" [
  subscriptionId: string
  resourceGroupName: string
  farmId: string
  operationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # REST Api Version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/Microsoft.Storage.Admin/farms/($farmId)/operationresults/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
