# Auto-generated client for VMwareCloudSimple v2019-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/vmwarecloudsimple/2019-04-01/swagger.json
# Auth: --token flag or $env.VMWARECLOUDSIMPLE_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VMWARECLOUDSIMPLE_TOKEN | default "" }
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
def mode-completer [] { ["poweroff" "reboot" "shutdown" "suspend"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-v-mware-cloud-simple-operations list" } } | get name | first)
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

# Implements list of available operations
#
# GET /providers/Microsoft.VMwareCloudSimple/operations
# operationId: Operations_List
export def "providers-microsoft-v-mware-cloud-simple-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<display: record, isDataAction: bool, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.VMwareCloudSimple/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements list of dedicated cloud nodes within subscription method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes
# operationId: DedicatedCloudNodes_ListBySubscription
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-nodes list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The filter to apply on the list operation
  --top: int # The maximum number of record sets to return (format: int32)
  --skip-token: string # to be used by nextLink implementation
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, sku: record, tags: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements list of dedicatedCloudService objects within subscription method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices
# operationId: DedicatedCloudServices_ListBySubscription
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-services list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The filter to apply on the list operation
  --top: int # The maximum number of record sets to return (format: int32)
  --skip-token: string # to be used by nextLink implementation
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, tags: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements SkuAvailability List method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/availabilities
# operationId: SkusAvailability_List
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-availabilities list-skus-availability" [
  subscription_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: string # sku id, if no sku is passed availability for all skus will be returned
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<dedicatedAvailabilityZoneId: string, dedicatedAvailabilityZoneName: string, dedicatedPlacementGroupId: string, dedicatedPlacementGroupName: string, limit: int, resourceType: string, skuId: string, skuName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $sku_id "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/availabilities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements get of async operation
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/operationResults/{operationId}
# operationId: Operations_Get
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-operation-results get" [
  subscription_id: string
  region_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --referer: string # referer url
]: nothing -> record<endTime: string, error: record<code: string, message: string>, id: string, name: string, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/operationResults/{operation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Referer": $referer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements private cloud list GET method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds
# operationId: PrivateClouds_List
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds list" [
  subscription_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements private cloud GET method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}
# operationId: PrivateClouds_Get
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds get" [
  subscription_id: string
  region_id: string
  pc_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<id: string, location: string, name: string, properties: record<availabilityZoneId: string, availabilityZoneName: string, clustersNumber: int, createdBy: string, createdOn: string, dnsServers: list<string>, expires: string, nsxType: string, placementGroupId: string, placementGroupName: string, privateCloudId: string, resourcePools: list<record>, state: string, totalCpuCores: int, totalNodes: int, totalRam: int, totalStorage: float, type: string, vSphereVersion: string, vcenterFqdn: string, vcenterRefid: string, virtualMachineTemplates: list<record>, virtualNetworks: list<record>, vrOpsEnabled: bool>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements get of customization policies list
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/customizationPolicies
# operationId: customizationPolicies_List
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-customization-policies list" [
  subscription_id: string
  region_id: string
  pc_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The filter to apply on the list operation. only type is allowed here as a filter e.g. $filter=type eq 'xxxx'
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/customizationPolicies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements get of customization policy
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/customizationPolicies/{customizationPolicyName}
# operationId: customizationPolicies_Get
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-customization-policies get" [
  subscription_id: string
  region_id: string
  pc_name: string
  customization_policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<id: string, location: string, name: string, properties: record<description: string, privateCloudId: string, specification: record<identity: record, nicSettings: list>, type: string, version: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name), customization_policy_name: (encode-path-segment $customization_policy_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/customizationPolicies/{customization_policy_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements get of resource pools list
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/resourcePools
# operationId: ResourcePools_List
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-resource-pools list" [
  subscription_id: string
  region_id: string
  pc_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, privateCloudId: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/resourcePools") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements get of resource pool
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/resourcePools/{resourcePoolName}
# operationId: ResourcePools_Get
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-resource-pools get" [
  subscription_id: string
  region_id: string
  pc_name: string
  resource_pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<id: string, location: string, name: string, privateCloudId: string, properties: record<fullName: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name), resource_pool_name: (encode-path-segment $resource_pool_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/resourcePools/{resource_pool_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements list of available VM templates
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/virtualMachineTemplates
# operationId: VirtualMachineTemplates_List
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-virtual-machine-templates list" [
  subscription_id: string
  region_id: string
  pc_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --resource-pool-name: string # Resource pool used to derive vSphere cluster which contains VM templates
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "resourcePoolName" $resource_pool_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/virtualMachineTemplates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements virtual machine template GET method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/virtualMachineTemplates/{virtualMachineTemplateName}
# operationId: VirtualMachineTemplates_Get
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-virtual-machine-templates get" [
  subscription_id: string
  region_id: string
  pc_name: string
  virtual_machine_template_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<id: string, location: string, name: string, properties: record<amountOfRam: int, controllers: list<record>, description: string, disks: list<record>, exposeToGuestVM: bool, guestOS: string, guestOSType: string, nics: list<record>, numberOfCores: int, path: string, privateCloudId: string, vSphereNetworks: list<string>, vSphereTags: list<string>, vmwaretools: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name), virtual_machine_template_name: (encode-path-segment $virtual_machine_template_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/virtualMachineTemplates/{virtual_machine_template_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements list available virtual networks within a subscription method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/virtualNetworks
# operationId: VirtualNetworks_List
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-virtual-networks list" [
  subscription_id: string
  region_id: string
  pc_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --resource-pool-name: string # Resource pool used to derive vSphere cluster which contains virtual networks
]: nothing -> record<nextLink: string, value: table<assignable: bool, id: string, location: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "resourcePoolName" $resource_pool_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/virtualNetworks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements virtual network GET method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/privateClouds/{pcName}/virtualNetworks/{virtualNetworkName}
# operationId: VirtualNetworks_Get
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-private-clouds-virtual-networks get" [
  subscription_id: string
  region_id: string
  pc_name: string
  virtual_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<assignable: bool, id: string, location: string, name: string, properties: record<privateCloudId: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id), pc_name: (encode-path-segment $pc_name), virtual_network_name: (encode-path-segment $virtual_network_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/privateClouds/{pc_name}/virtualNetworks/{virtual_network_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements Usages List method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/locations/{regionId}/usages
# operationId: Usages_List
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-locations-usages list" [
  subscription_id: string
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The filter to apply on the list operation. only name.value is allowed here as a filter e.g. $filter=name.value eq 'xxxx'
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), region_id: (encode-path-segment $region_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/locations/{region_id}/usages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements list virtual machine within subscription method
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.VMwareCloudSimple/virtualMachines
# operationId: VirtualMachines_ListBySubscription
export def "subscriptions-providers-microsoft-v-mware-cloud-simple-virtual-machines list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --filter: string # The filter to apply on the list operation
  --top: int # The maximum number of record sets to return (format: int32)
  --skip-token: string # to be used by nextLink implementation
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, tags: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.VMwareCloudSimple/virtualMachines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements list of dedicated cloud nodes within RG method
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes
# operationId: DedicatedCloudNodes_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-nodes list" [
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
  --api-version: string # Client API version.
  --filter: string # The filter to apply on the list operation
  --top: int # The maximum number of record sets to return (format: int32)
  --skip-token: string # to be used by nextLink implementation
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, sku: record, tags: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements dedicated cloud node DELETE method
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicatedCloudNodeName}
# operationId: DedicatedCloudNodes_Delete
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-nodes delete" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_node_name: (encode-path-segment $dedicated_cloud_node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicated_cloud_node_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements dedicated cloud node GET method
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicatedCloudNodeName}
# operationId: DedicatedCloudNodes_Get
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-nodes get" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<id: string, location: string, name: string, properties: record<availabilityZoneId: string, availabilityZoneName: string, cloudRackName: string, created: any, nodesCount: int, placementGroupId: string, placementGroupName: string, privateCloudId: string, privateCloudName: string, provisioningState: string, purchaseId: string, skuDescription: record<id: string, name: string>, status: string, vmwareClusterName: string>, sku: record<capacity: string, description: string, family: string, name: string, tier: string>, tags: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_node_name: (encode-path-segment $dedicated_cloud_node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicated_cloud_node_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements dedicated cloud node PATCH method
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicatedCloudNodeName}
# operationId: DedicatedCloudNodes_Update
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-nodes update" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: any # Tags model
]: any -> record<id: string, location: string, name: string, properties: record<availabilityZoneId: string, availabilityZoneName: string, cloudRackName: string, created: any, nodesCount: int, placementGroupId: string, placementGroupName: string, privateCloudId: string, privateCloudName: string, provisioningState: string, purchaseId: string, skuDescription: record<id: string, name: string>, status: string, vmwareClusterName: string>, sku: record<capacity: string, description: string, family: string, name: string, tier: string>, tags: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_node_name: (encode-path-segment $dedicated_cloud_node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicated_cloud_node_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Implements dedicated cloud node PUT method
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicatedCloudNodeName}
# operationId: DedicatedCloudNodes_CreateOrUpdate
# --properties shape: {availabilityZoneId: string, nodesCount: int, placementGroupId: string, purchaseId: string, skuDescription?: any}
# --sku shape: {capacity?: string, description?: string, family?: string, name: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-nodes create-or-update" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_node_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --referer: string # referer url
  location: string # Azure region
  --properties: any # Properties of dedicated cloud node — shape: {availabilityZoneId: string, nodesCount: int, placementGroupId: string, purchaseId: string, skuDescription?: any}
  --sku: any # The purchase SKU for CloudSimple paid resources — shape: {capacity?: string, description?: string, family?: string, name: string, tier?: string}
  --tags: any # Tags model
]: any -> record<id: string, location: string, name: string, properties: record<availabilityZoneId: string, availabilityZoneName: string, cloudRackName: string, created: any, nodesCount: int, placementGroupId: string, placementGroupName: string, privateCloudId: string, privateCloudName: string, provisioningState: string, purchaseId: string, skuDescription: record<id: string, name: string>, status: string, vmwareClusterName: string>, sku: record<capacity: string, description: string, family: string, name: string, tier: string>, tags: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_node_name: (encode-path-segment $dedicated_cloud_node_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudNodes/{dedicated_cloud_node_name}") $qp)
  let req_body = {"location": $location, "properties": $properties, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Referer": $referer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Implements list of dedicatedCloudService objects within RG method
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices
# operationId: DedicatedCloudServices_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-services list" [
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
  --api-version: string # Client API version.
  --filter: string # The filter to apply on the list operation
  --top: int # The maximum number of record sets to return (format: int32)
  --skip-token: string # to be used by nextLink implementation
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, tags: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements dedicatedCloudService DELETE method
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicatedCloudServiceName}
# operationId: DedicatedCloudServices_Delete
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-services delete" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_service_name: (encode-path-segment $dedicated_cloud_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicated_cloud_service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements dedicatedCloudService GET method
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicatedCloudServiceName}
# operationId: DedicatedCloudServices_Get
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-services get" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<id: string, location: string, name: string, properties: record<gatewaySubnet: string, isAccountOnboarded: string, nodes: int, serviceURL: string>, tags: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_service_name: (encode-path-segment $dedicated_cloud_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicated_cloud_service_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements dedicatedCloudService PATCH method
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicatedCloudServiceName}
# operationId: DedicatedCloudServices_Update
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-services update" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: any # Tags model
]: any -> record<id: string, location: string, name: string, properties: record<gatewaySubnet: string, isAccountOnboarded: string, nodes: int, serviceURL: string>, tags: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_service_name: (encode-path-segment $dedicated_cloud_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicated_cloud_service_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Implements dedicated cloud service PUT method
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicatedCloudServiceName}
# operationId: DedicatedCloudServices_CreateOrUpdate
# --properties shape: {gatewaySubnet: string}
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-dedicated-cloud-services create-or-update" [
  subscription_id: string
  resource_group_name: string
  dedicated_cloud_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  location: string # Azure region
  --properties: any # Properties of dedicated cloud service — shape: {gatewaySubnet: string}
  --tags: any # Tags model
]: any -> record<id: string, location: string, name: string, properties: record<gatewaySubnet: string, isAccountOnboarded: string, nodes: int, serviceURL: string>, tags: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), dedicated_cloud_service_name: (encode-path-segment $dedicated_cloud_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/dedicatedCloudServices/{dedicated_cloud_service_name}") $qp)
  let req_body = {"location": $location, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Implements list virtual machine within RG method
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/virtualMachines
# operationId: VirtualMachines_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-virtual-machines list" [
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
  --api-version: string # Client API version.
  --filter: string # The filter to apply on the list operation
  --top: int # The maximum number of record sets to return (format: int32)
  --skip-token: string # to be used by nextLink implementation
]: nothing -> record<nextLink: string, value: table<id: string, location: string, name: string, properties: record, tags: any, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skipToken" $skip_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/virtualMachines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements virtual machine DELETE method
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtualMachineName}
# operationId: VirtualMachines_Delete
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-virtual-machines delete" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --referer: string # referer url
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtual_machine_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Referer": $referer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements virtual machine GET method
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtualMachineName}
# operationId: VirtualMachines_Get
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-virtual-machines get" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<id: string, location: string, name: string, properties: record<amountOfRam: int, controllers: list<record>, customization: record<dnsServers: list, hostName: string, password: string, policyId: string, username: string>, disks: list<record>, dnsname: string, exposeToGuestVM: bool, folder: string, guestOS: string, guestOSType: string, nics: list<record>, numberOfCores: int, password: string, privateCloudId: string, provisioningState: string, publicIP: string, resourcePool: record<id: string, location: string, name: string, privateCloudId: string, properties: record, type: string>, status: string, templateId: string, username: string, vSphereNetworks: list<string>, vmId: string, vmwaretools: string>, tags: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtual_machine_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements virtual machine PATCH method
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtualMachineName}
# operationId: VirtualMachines_Update
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-virtual-machines update" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: any # Tags model
]: any -> record<id: string, location: string, name: string, properties: record<amountOfRam: int, controllers: list<record>, customization: record<dnsServers: list, hostName: string, password: string, policyId: string, username: string>, disks: list<record>, dnsname: string, exposeToGuestVM: bool, folder: string, guestOS: string, guestOSType: string, nics: list<record>, numberOfCores: int, password: string, privateCloudId: string, provisioningState: string, publicIP: string, resourcePool: record<id: string, location: string, name: string, privateCloudId: string, properties: record, type: string>, status: string, templateId: string, username: string, vSphereNetworks: list<string>, vmId: string, vmwaretools: string>, tags: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtual_machine_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Implements virtual machine PUT method
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtualMachineName}
# operationId: VirtualMachines_CreateOrUpdate
# --properties shape: {amountOfRam: int, customization?: any, disks?: list, exposeToGuestVM?: bool, nics?: list, numberOfCores: int, password?: string, privateCloudId: string, resourcePool?: any, templateId?: string, username?: string, vSphereNetworks?: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-virtual-machines create-or-update" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --referer: string # referer url
  location: string # Azure region
  --properties: any # Properties of virtual machine — shape: {amountOfRam: int, customization?: any, disks?: list, exposeToGuestVM?: bool, nics?: list, numberOfCores: int, password?: string, privateCloudId: string, resourcePool?: any, templateId?: string, username?: string, vSphereNetworks?: list<string>}
  --tags: any # Tags model
]: any -> record<id: string, location: string, name: string, properties: record<amountOfRam: int, controllers: list<record>, customization: record<dnsServers: list, hostName: string, password: string, policyId: string, username: string>, disks: list<record>, dnsname: string, exposeToGuestVM: bool, folder: string, guestOS: string, guestOSType: string, nics: list<record>, numberOfCores: int, password: string, privateCloudId: string, provisioningState: string, publicIP: string, resourcePool: record<id: string, location: string, name: string, privateCloudId: string, properties: record, type: string>, status: string, templateId: string, username: string, vSphereNetworks: list<string>, vmId: string, vmwaretools: string>, tags: any, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtual_machine_name}") $qp)
  let req_body = {"location": $location, "properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Referer": $referer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Implements a start method for a virtual machine
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtualMachineName}/start
# operationId: VirtualMachines_Start
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-virtual-machines-start start" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --referer: string # referer url
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtual_machine_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Referer": $referer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Implements shutdown, poweroff, and suspend method for a virtual machine
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtualMachineName}/stop
# operationId: VirtualMachines_Stop
export def "subscriptions-resource-groups-providers-microsoft-v-mware-cloud-simple-virtual-machines-stop stop" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer # query stop mode parameter (reboot, shutdown, etc...)
  --api-version: string # Client API version.
  --referer: string # referer url
  --mode: string@mode-completer # mode indicates a type of stop operation - reboot, suspend, shutdown or power-off
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.VMwareCloudSimple/virtualMachines/{virtual_machine_name}/stop") $qp)
  let req_body = {"mode": $mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Referer": $referer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
