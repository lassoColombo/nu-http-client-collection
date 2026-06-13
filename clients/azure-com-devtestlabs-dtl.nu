# Auto-generated client for DevTestLabsClient v2018-09-15
# Source: https://api.apis.guru/v2/specs/azure.com/devtestlabs-DTL/2018-09-15/swagger.json
# Auth: --token flag or $env.DEVTESTLABSCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DEVTESTLABSCLIENT_TOKEN | default "" }
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
def fileUploadOptions-completer [] { ["None" "UploadFilesAndGenerateSasTokens"] }
def eventName-completer [] { ["AutoShutdown" "Cost"] }
def hostCaching-completer [] { ["None" "ReadOnly" "ReadWrite"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-dev-test-lab-operations List" } } | get name | first)
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

# Result of the request to list REST API operations
#
# GET /providers/Microsoft.DevTestLab/operations
# operationId: ProviderOperations_List
export def "providers-microsoft-dev-test-lab-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DevTestLab/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List labs in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/labs
# operationId: Labs_ListBySubscription
export def "subscriptions-providers-microsoft-dev-test-lab-labs ListBySubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DevTestLab/labs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get operation.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/locations/{locationName}/operations/{name}
# operationId: Operations_Get
export def "subscriptions-providers-microsoft-dev-test-lab-locations-operations Get" [
  subscriptionId: string
  locationName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, message: string>, status: string, statusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DevTestLab/locations/($locationName)/operations/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List schedules in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/schedules
# operationId: GlobalSchedules_ListBySubscription
export def "subscriptions-providers-microsoft-dev-test-lab-schedules ListBySubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DevTestLab/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List labs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs
# operationId: Labs_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs ListByResourceGroup" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List artifact sources in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources
# operationId: ArtifactSources_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List azure resource manager templates in a given artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates
# operationId: ArmTemplates_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-armtemplates List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  artifactSourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($artifactSourceName)/armtemplates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get azure resource manager template.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates/{name}
# operationId: ArmTemplates_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-armtemplates Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  artifactSourceName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<contents: record, createdDate: string, description: string, displayName: string, enabled: bool, icon: string, parametersValueFilesInfo: list<record>, publisher: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($artifactSourceName)/armtemplates/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List artifacts in a given artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts
# operationId: Artifacts_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-artifacts List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  artifactSourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=title)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($artifactSourceName)/artifacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get artifact.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}
# operationId: Artifacts_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-artifacts Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  artifactSourceName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=title)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, description: string, filePath: string, icon: string, parameters: record, publisher: string, targetOsType: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($artifactSourceName)/artifacts/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates an ARM template for the given artifact, uploads the required files to a storage account, and validates the generated artifact.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}/generateArmTemplate
# operationId: Artifacts_GenerateArmTemplate
# --parameters item shape: {name?: string, value?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-artifacts-generate-arm-template GenerateArmTemplate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  artifactSourceName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --fileUploadOptions: string@fileUploadOptions-completer # Options for uploading the files for the artifact. UploadFilesAndGenerateSasTokens is the default value.
  --location: string # The location of the virtual machine.
  --parameters: list # The parameters of the ARM template. — item shape: {name?: string, value?: string}
  --virtualMachineName: string # The resource name of the virtual machine.
]: any -> record<parameters: record, template: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($artifactSourceName)/artifacts/($name)/generateArmTemplate" $qp)
  let body = {fileUploadOptions: $fileUploadOptions, location: $location, parameters: $parameters, virtualMachineName: $virtualMachineName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete artifact source.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of artifact sources. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_Update
# --properties shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of an artifact source. — shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing artifact source.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_CreateOrUpdate
# --properties shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of an artifact source. — shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/artifactsources/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get cost.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}
# operationId: Costs_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-costs Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=labCostDetails)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/costs/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace an existing cost.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}
# operationId: Costs_CreateOrUpdate
# --properties shape: {createdDate?: string, currencyCode?: string, endDateTime?: string, labCostSummary?: record, startDateTime?: string, targetCost?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-costs CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a cost item. — shape: {createdDate?: string, currencyCode?: string, endDateTime?: string, labCostSummary?: record, startDateTime?: string, targetCost?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/costs/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List custom images in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages
# operationId: CustomImages_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=vm)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/customimages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete custom image. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/customimages/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom image.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=vm)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/customimages/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of custom images. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_Update
# --properties shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a custom image. — shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/customimages/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing custom image. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_CreateOrUpdate
# --properties shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a custom image. — shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/customimages/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List formulas in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas
# operationId: Formulas_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/formulas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete formula.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/formulas/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get formula.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/formulas/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of formulas. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_Update
# --properties shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a formula. — shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/formulas/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing formula. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_CreateOrUpdate
# --properties shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a formula. — shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/formulas/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List gallery images in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/galleryimages
# operationId: GalleryImages_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-galleryimages List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=author)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/galleryimages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List notification channels in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels
# operationId: NotificationChannels_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=webHookUrl)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/notificationchannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete notification channel.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/notificationchannels/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notification channel.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=webHookUrl)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/notificationchannels/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of notification channels. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_Update
# --properties shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/notificationchannels/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing notification channel.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_CreateOrUpdate
# --properties shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/notificationchannels/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send notification to provided channel.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}/notify
# operationId: NotificationChannels_Notify
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels-notify Notify" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --eventName: string@eventName-completer # The type of event (i.e. AutoShutdown, Cost)
  --jsonPayload: string # Properties for the notification in json format.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/notificationchannels/($name)/notify" $qp)
  let body = {eventName: $eventName, jsonPayload: $jsonPayload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Evaluates lab policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{name}/evaluatePolicies
# operationId: PolicySets_EvaluatePolicies
# --policies item shape: {factData?: string, factName?: string, userObjectId?: string, valueOffset?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-evaluate-policies EvaluatePolicies" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --policies: list # Policies to evaluate. — item shape: {factData?: string, factName?: string, userObjectId?: string, valueOffset?: string}
]: any -> record<results: table<hasError: bool, policyViolations: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/policysets/($name)/evaluatePolicies" $qp)
  let body = {policies: $policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List policies in a given policy set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies
# operationId: Policies_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  policySetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/policysets/($policySetName)/policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete policy.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  policySetName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/policysets/($policySetName)/policies/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get policy.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  policySetName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/policysets/($policySetName)/policies/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of policies. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_Update
# --properties shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  policySetName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a Policy. — shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/policysets/($policySetName)/policies/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing policy.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_CreateOrUpdate
# --properties shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  policySetName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a Policy. — shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/policysets/($policySetName)/policies/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List schedules in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules
# operationId: Schedules_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/schedules/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/schedules/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/execute
# operationId: Schedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules-execute Execute" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/schedules/($name)/execute" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all applicable schedules
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/listApplicable
# operationId: Schedules_ListApplicable
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules-list-applicable ListApplicable" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/schedules/($name)/listApplicable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete service runner.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# operationId: ServiceRunners_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-servicerunners Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/servicerunners/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get service runner.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# operationId: ServiceRunners_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-servicerunners Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/servicerunners/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace an existing service runner.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# operationId: ServiceRunners_CreateOrUpdate
# --identity shape: {clientSecretUrl?: string, principalId?: string, tenantId?: string, type?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-servicerunners CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --identity: record # Properties of a managed identity — shape: {clientSecretUrl?: string, principalId?: string, tenantId?: string, type?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/servicerunners/($name)" $qp)
  let body = {identity: $identity, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List user profiles in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users
# operationId: Users_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=identity)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user profile. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=identity)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of user profiles. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_Update
# --properties shape: {identity?: record, secretStore?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab user profile. — shape: {identity?: record, secretStore?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing user profile. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_CreateOrUpdate
# --properties shape: {identity?: record, secretStore?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab user profile. — shape: {identity?: record, secretStore?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List disks in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks
# operationId: Disks_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=diskType)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/disks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete disk. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/disks/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get disk.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=diskType)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/disks/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of disks. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_Update
# --properties shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a disk. — shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/disks/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing disk. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_CreateOrUpdate
# --properties shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a disk. — shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/disks/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Attach and create the lease of the disk to the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/attach
# operationId: Disks_Attach
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks-attach Attach" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --leasedByLabVmId: string # The resource ID of the Lab virtual machine to which the disk is attached.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/disks/($name)/attach" $qp)
  let body = {leasedByLabVmId: $leasedByLabVmId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Detach and break the lease of the disk attached to the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/detach
# operationId: Disks_Detach
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks-detach Detach" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --leasedByLabVmId: string # The resource ID of the Lab VM to which the disk is attached.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/disks/($name)/detach" $qp)
  let body = {leasedByLabVmId: $leasedByLabVmId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List environments in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments
# operationId: Environments_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=deploymentProperties)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete environment. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/environments/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=deploymentProperties)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/environments/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of environments. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_Update
# --properties shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of an environment. — shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/environments/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing environment. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_CreateOrUpdate
# --properties shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of an environment. — shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/environments/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List secrets in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets
# operationId: Secrets_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=value)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete secret.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/secrets/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get secret.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=value)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/secrets/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of secrets. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_Update
# --properties shape: {value?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a secret. — shape: {value?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/secrets/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing secret. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_CreateOrUpdate
# --properties shape: {value?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a secret. — shape: {value?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/secrets/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List service fabrics in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics
# operationId: ServiceFabrics_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=applicableSchedule)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete service fabric. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get service fabric.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=applicableSchedule)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<applicableSchedule: record<properties: record>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of service fabrics. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_Update
# --properties shape: {environmentId?: string, externalServiceFabricId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a service fabric. — shape: {environmentId?: string, externalServiceFabricId?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<applicableSchedule: record<properties: record>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing service fabric. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_CreateOrUpdate
# --properties shape: {applicableSchedule?: record, environmentId?: string, externalServiceFabricId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a service fabric. — shape: {applicableSchedule?: record, environmentId?: string, externalServiceFabricId?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<applicableSchedule: record<properties: record>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the applicable start/stop schedules, if any.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/listApplicableSchedules
# operationId: ServiceFabrics_ListApplicableSchedules
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-list-applicable-schedules ListApplicableSchedules" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<labVmsShutdown: record<properties: record>, labVmsStartup: record<properties: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($name)/listApplicableSchedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a service fabric. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/start
# operationId: ServiceFabrics_Start
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-start Start" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($name)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a service fabric This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/stop
# operationId: ServiceFabrics_Stop
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-stop Stop" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($name)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List schedules in a given service fabric.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules
# operationId: ServiceFabricSchedules_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  serviceFabricName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($serviceFabricName)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  serviceFabricName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($serviceFabricName)/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  serviceFabricName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($serviceFabricName)/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  serviceFabricName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($serviceFabricName)/schedules/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  serviceFabricName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($serviceFabricName)/schedules/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}/execute
# operationId: ServiceFabricSchedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules-execute Execute" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  userName: string
  serviceFabricName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/users/($userName)/servicefabrics/($serviceFabricName)/schedules/($name)/execute" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List virtual machines in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines
# operationId: VirtualMachines_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=artifacts,computeVm,networkInterface,applicableSchedule)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete virtual machine. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=artifacts,computeVm,networkInterface,applicableSchedule)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of virtual machines. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_Update
# --properties shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, notes?: string, osType?: string, ownerObjectId?: string, ownerUserPrincipalName?: string, password?: string, planId?: string, scheduleParameters?: list, size?: string, sshKey?: string, storageType?: string, userName?: string, virtualMachineCreationSource?: "FromCustomImage"|"FromGalleryImage"|"FromSharedGalleryImage"}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a virtual machine. — shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, notes?: string, osType?: string, ownerObjectId?: string, ownerUserPrincipalName?: string, password?: string, planId?: string, scheduleParameters?: list, size?: string, sshKey?: string, storageType?: string, userName?: string, virtualMachineCreationSource?: "FromCustomImage"|"FromGalleryImage"|"FromSharedGalleryImage"}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing virtual machine. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_CreateOrUpdate
# --properties shape: {allowClaim?: bool, applicableSchedule?: record, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, computeVm?: record, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, notes?: string, osType?: string, ownerObjectId?: string, ownerUserPrincipalName?: string, password?: string, planId?: string, scheduleParameters?: list, size?: string, sshKey?: string, storageType?: string, userName?: string, virtualMachineCreationSource?: "FromCustomImage"|"FromGalleryImage"|"FromSharedGalleryImage"}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a virtual machine. — shape: {allowClaim?: bool, applicableSchedule?: record, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, computeVm?: record, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, notes?: string, osType?: string, ownerObjectId?: string, ownerUserPrincipalName?: string, password?: string, planId?: string, scheduleParameters?: list, size?: string, sshKey?: string, storageType?: string, userName?: string, virtualMachineCreationSource?: "FromCustomImage"|"FromGalleryImage"|"FromSharedGalleryImage"}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Attach a new or existing data disk to virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/addDataDisk
# operationId: VirtualMachines_AddDataDisk
# --attachNewDataDiskOptions shape: {diskName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD"}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-add-data-disk AddDataDisk" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --attachNewDataDiskOptions: record # Properties to attach new disk to the Virtual Machine. — shape: {diskName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD"}
  --existingLabDiskId: string # Specifies the existing lab disk id to attach to virtual machine.
  --hostCaching: string@hostCaching-completer # Caching option for a data disk (i.e. None, ReadOnly, ReadWrite).
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/addDataDisk" $qp)
  let body = {attachNewDataDiskOptions: $attachNewDataDiskOptions, existingLabDiskId: $existingLabDiskId, hostCaching: $hostCaching} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Apply artifacts to virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/applyArtifacts
# operationId: VirtualMachines_ApplyArtifacts
# --artifacts item shape: {artifactId?: string, artifactTitle?: string, deploymentStatusMessage?: string, installTime?: string, parameters?: list, status?: string, vmExtensionStatusMessage?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-apply-artifacts ApplyArtifacts" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --artifacts: list # The list of artifacts to apply. — item shape: {artifactId?: string, artifactTitle?: string, deploymentStatusMessage?: string, installTime?: string, parameters?: list, status?: string, vmExtensionStatusMessage?: string}
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/applyArtifacts" $qp)
  let body = {artifacts: $artifacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Take ownership of an existing virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/claim
# operationId: VirtualMachines_Claim
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-claim Claim" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/claim" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach the specified disk from the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/detachDataDisk
# operationId: VirtualMachines_DetachDataDisk
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-detach-data-disk DetachDataDisk" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --existingLabDiskId: string # Specifies the disk resource ID to detach from virtual machine.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/detachDataDisk" $qp)
  let body = {existingLabDiskId: $existingLabDiskId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a string that represents the contents of the RDP file for the virtual machine
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/getRdpFileContents
# operationId: VirtualMachines_GetRdpFileContents
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-get-rdp-file-contents GetRdpFileContents" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<contents: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/getRdpFileContents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the applicable start/stop schedules, if any.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/listApplicableSchedules
# operationId: VirtualMachines_ListApplicableSchedules
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-list-applicable-schedules ListApplicableSchedules" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<labVmsShutdown: record<properties: record>, labVmsStartup: record<properties: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/listApplicableSchedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Redeploy a virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/redeploy
# operationId: VirtualMachines_Redeploy
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-redeploy Redeploy" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/redeploy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resize Virtual Machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/resize
# operationId: VirtualMachines_Resize
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-resize Resize" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --size: string # Specifies the size of the virtual machine.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/resize" $qp)
  let body = {size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restart a virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/restart
# operationId: VirtualMachines_Restart
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-restart Restart" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/start
# operationId: VirtualMachines_Start
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-start Start" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/stop
# operationId: VirtualMachines_Stop
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-stop Stop" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfers all data disks attached to the virtual machine to be owned by the current user. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/transferDisks
# operationId: VirtualMachines_TransferDisks
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-transfer-disks TransferDisks" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/transferDisks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Release ownership of an existing virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/unClaim
# operationId: VirtualMachines_UnClaim
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-un-claim UnClaim" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($name)/unClaim" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List schedules in a given virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules
# operationId: VirtualMachineSchedules_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  virtualMachineName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($virtualMachineName)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  virtualMachineName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($virtualMachineName)/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  virtualMachineName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($virtualMachineName)/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  virtualMachineName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($virtualMachineName)/schedules/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  virtualMachineName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($virtualMachineName)/schedules/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}/execute
# operationId: VirtualMachineSchedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules-execute Execute" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  virtualMachineName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualmachines/($virtualMachineName)/schedules/($name)/execute" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List virtual networks in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks
# operationId: VirtualNetworks_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks List" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=externalSubnets)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualnetworks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete virtual network. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks Delete" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualnetworks/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks Get" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=externalSubnets)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualnetworks/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of virtual networks. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_Update
# --properties shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks Update" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a virtual network. — shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualnetworks/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing virtual network. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_CreateOrUpdate
# --properties shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  labName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a virtual network. — shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($labName)/virtualnetworks/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete lab. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs Delete" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs Get" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of labs. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_Update
# --properties shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list, mandatoryArtifactsResourceIdsWindows?: list, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs Update" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab. — shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list, mandatoryArtifactsResourceIdsWindows?: list, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing lab. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_CreateOrUpdate
# --properties shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list, mandatoryArtifactsResourceIdsWindows?: list, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab. — shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list, mandatoryArtifactsResourceIdsWindows?: list, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Claim a random claimable virtual machine in the lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/claimAnyVm
# operationId: Labs_ClaimAnyVm
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-claim-any-vm ClaimAnyVm" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)/claimAnyVm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create virtual machines in a lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/createEnvironment
# operationId: Labs_CreateEnvironment
# --properties shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, bulkCreationParameters?: record, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, notes?: string, osType?: string, ownerObjectId?: string, ownerUserPrincipalName?: string, password?: string, planId?: string, scheduleParameters?: list, size?: string, sshKey?: string, storageType?: string, userName?: string, virtualMachineCreationSource?: "FromCustomImage"|"FromGalleryImage"|"FromSharedGalleryImage"}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-create-environment CreateEnvironment" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --location: string # The location of the new virtual machine or environment
  --body-name: string # The name of the virtual machine or environment
  --properties: record # Properties for virtual machine creation. — shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, bulkCreationParameters?: record, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, notes?: string, osType?: string, ownerObjectId?: string, ownerUserPrincipalName?: string, password?: string, planId?: string, scheduleParameters?: list, size?: string, sshKey?: string, storageType?: string, userName?: string, virtualMachineCreationSource?: "FromCustomImage"|"FromGalleryImage"|"FromSharedGalleryImage"}
  --tags: record # The tags of the resource.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)/createEnvironment" $qp)
  let body = {location: $location, name: $body_name, properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exports the lab resource usage into a storage account This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/exportResourceUsage
# operationId: Labs_ExportResourceUsage
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-export-resource-usage ExportResourceUsage" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --blobStorageAbsoluteSasUri: string # The blob storage absolute sas uri with write permission to the container which the usage data needs to be uploaded to.
  --usageStartDate: string # The start time of the usage. If not provided, usage will be reported since the beginning of data collection. (format: date-time)
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)/exportResourceUsage" $qp)
  let body = {blobStorageAbsoluteSasUri: $blobStorageAbsoluteSasUri, usageStartDate: $usageStartDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a URI for uploading custom disk images to a Lab.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/generateUploadUri
# operationId: Labs_GenerateUploadUri
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-generate-upload-uri GenerateUploadUri" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --blobName: string # The blob name of the upload URI.
]: any -> record<uploadUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)/generateUploadUri" $qp)
  let body = {blobName: $blobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import a virtual machine into a different lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/importVirtualMachine
# operationId: Labs_ImportVirtualMachine
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-import-virtual-machine ImportVirtualMachine" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --destinationVirtualMachineName: string # The name of the virtual machine in the destination lab
  --sourceVirtualMachineResourceId: string # The full resource ID of the virtual machine to be imported.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)/importVirtualMachine" $qp)
  let body = {destinationVirtualMachineName: $destinationVirtualMachineName, sourceVirtualMachineResourceId: $sourceVirtualMachineResourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List disk images available for custom image creation.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/listVhds
# operationId: Labs_ListVhds
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-list-vhds ListVhds" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/labs/($name)/listVhds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List schedules in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules
# operationId: GlobalSchedules_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules ListByResourceGroup" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules Delete" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules Get" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/schedules/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules Update" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/schedules/($name)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/schedules/($name)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/execute
# operationId: GlobalSchedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules-execute Execute" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/schedules/($name)/execute" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a schedule's target resource Id. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/retarget
# operationId: GlobalSchedules_Retarget
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules-retarget Retarget" [
  subscriptionId: string
  resourceGroupName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --currentResourceId: string # The resource Id of the virtual machine on which the schedule operates
  --targetResourceId: string # The resource Id of the virtual machine that the schedule should be retargeted to
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DevTestLab/schedules/($name)/retarget" $qp)
  let body = {currentResourceId: $currentResourceId, targetResourceId: $targetResourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
