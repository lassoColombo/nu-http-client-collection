# Auto-generated client for Azure ML Web Services Management Client v2017-01-01
# Source: https://api.apis.guru/v2/specs/azure.com/machinelearning-webservices/2017-01-01/swagger.json
# Auth: --token flag or $env.AZURE_ML_WEB_SERVICES_MANAGEMENT_CLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_ML_WEB_SERVICES_MANAGEMENT_CLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-machine-learning-operations List" } } | get name | first)
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

# Lists all the available REST API operations.
#
# GET /providers/Microsoft.MachineLearning/operations
# operationId: Operations_List
export def "providers-microsoft-machine-learning-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
]: nothing -> record<value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.MachineLearning/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the web services in the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.MachineLearning/webServices
# operationId: WebServices_ListBySubscriptionId
export def "subscriptions-providers-microsoft-machine-learning-web-services ListBySubscriptionId" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skiptoken: string # Continuation token for pagination.
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$skiptoken" $skiptoken "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.MachineLearning/webServices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the web services in the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearning/webServices
# operationId: WebServices_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-machine-learning-web-services ListByResourceGroup" [
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
  --skiptoken: string # Continuation token for pagination.
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$skiptoken" $skiptoken "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearning/webServices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the specified web service.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearning/webServices/{webServiceName}
# operationId: WebServices_Remove
export def "subscriptions-resource-groups-providers-microsoft-machine-learning-web-services Remove" [
  resourceGroupName: string
  webServiceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearning/webServices/($webServiceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Web Service Definition as specified by a subscription, resource group, and name. Note that the storage credentials and web service keys are not returned by this call. To get the web service access keys, call List Keys.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearning/webServices/{webServiceName}
# operationId: WebServices_Get
export def "subscriptions-resource-groups-providers-microsoft-machine-learning-web-services Get" [
  resourceGroupName: string
  webServiceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --region: string # The region for which encrypted credential parameters are valid.
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
]: nothing -> record<properties: record<assets: record, commitmentPlan: record<id: string>, createdOn: string, description: string, diagnostics: record<expiry: string, level: string>, exampleRequest: record<globalParameters: record, inputs: record>, exposeSampleData: bool, input: record<description: string, properties: record, title: string, type: string>, keys: record<primary: string, secondary: string>, machineLearningWorkspace: record<id: string>, modifiedOn: string, output: record<description: string, properties: record, title: string, type: string>, packageType: string, parameters: record, payloadsInBlobStorage: bool, payloadsLocation: record<credentials: string, uri: string>, provisioningState: string, readOnly: bool, realtimeConfiguration: record<maxConcurrentCalls: int>, storageAccount: record<key: string, name: string>, swaggerLocation: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearning/webServices/($webServiceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modifies an existing web service resource. The PATCH API call is an asynchronous operation. To determine whether it has completed successfully, you must perform a Get operation.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearning/webServices/{webServiceName}
# operationId: WebServices_Patch
# --properties shape: {assets?: record, commitmentPlan?: record, description?: string, diagnostics?: record, exampleRequest?: record, exposeSampleData?: bool, input?: record, keys?: record, machineLearningWorkspace?: record, output?: record, packageType: "Graph", parameters?: record, payloadsInBlobStorage?: bool, payloadsLocation?: record, readOnly?: bool, realtimeConfiguration?: record, storageAccount?: record, title?: string}
export def "subscriptions-resource-groups-providers-microsoft-machine-learning-web-services Patch" [
  resourceGroupName: string
  webServiceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
  --properties: record # The set of properties specific to the Azure ML web service resource. — shape: {assets?: record, commitmentPlan?: record, description?: string, diagnostics?: record, exampleRequest?: record, exposeSampleData?: bool, input?: record, keys?: record, machineLearningWorkspace?: record, output?: record, packageType: "Graph", parameters?: record, payloadsInBlobStorage?: bool, payloadsLocation?: record, readOnly?: bool, realtimeConfiguration?: record, storageAccount?: record, title?: string}
  --tags: record # Contains resource tags defined as key/value pairs.
]: any -> record<properties: record<assets: record, commitmentPlan: record<id: string>, createdOn: string, description: string, diagnostics: record<expiry: string, level: string>, exampleRequest: record<globalParameters: record, inputs: record>, exposeSampleData: bool, input: record<description: string, properties: record, title: string, type: string>, keys: record<primary: string, secondary: string>, machineLearningWorkspace: record<id: string>, modifiedOn: string, output: record<description: string, properties: record, title: string, type: string>, packageType: string, parameters: record, payloadsInBlobStorage: bool, payloadsLocation: record<credentials: string, uri: string>, provisioningState: string, readOnly: bool, realtimeConfiguration: record<maxConcurrentCalls: int>, storageAccount: record<key: string, name: string>, swaggerLocation: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearning/webServices/($webServiceName)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or update a web service. This call will overwrite an existing web service. Note that there is no warning or confirmation. This is a nonrecoverable operation. If your intent is to create a new web service, call the Get operation first to verify that it does not exist.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearning/webServices/{webServiceName}
# operationId: WebServices_CreateOrUpdate
# --properties shape: {assets?: record, commitmentPlan?: record, description?: string, diagnostics?: record, exampleRequest?: record, exposeSampleData?: bool, input?: record, keys?: record, machineLearningWorkspace?: record, output?: record, packageType: "Graph", parameters?: record, payloadsInBlobStorage?: bool, payloadsLocation?: record, readOnly?: bool, realtimeConfiguration?: record, storageAccount?: record, title?: string}
export def "subscriptions-resource-groups-providers-microsoft-machine-learning-web-services CreateOrUpdate" [
  resourceGroupName: string
  webServiceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
  properties: record # The set of properties specific to the Azure ML web service resource. — shape: {assets?: record, commitmentPlan?: record, description?: string, diagnostics?: record, exampleRequest?: record, exposeSampleData?: bool, input?: record, keys?: record, machineLearningWorkspace?: record, output?: record, packageType: "Graph", parameters?: record, payloadsInBlobStorage?: bool, payloadsLocation?: record, readOnly?: bool, realtimeConfiguration?: record, storageAccount?: record, title?: string}
  location: string # Specifies the location of the resource.
  --tags: record # Contains resource tags defined as key/value pairs.
]: any -> record<properties: record<assets: record, commitmentPlan: record<id: string>, createdOn: string, description: string, diagnostics: record<expiry: string, level: string>, exampleRequest: record<globalParameters: record, inputs: record>, exposeSampleData: bool, input: record<description: string, properties: record, title: string, type: string>, keys: record<primary: string, secondary: string>, machineLearningWorkspace: record<id: string>, modifiedOn: string, output: record<description: string, properties: record, title: string, type: string>, packageType: string, parameters: record, payloadsInBlobStorage: bool, payloadsLocation: record<credentials: string, uri: string>, provisioningState: string, readOnly: bool, realtimeConfiguration: record<maxConcurrentCalls: int>, storageAccount: record<key: string, name: string>, swaggerLocation: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearning/webServices/($webServiceName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an encrypted credentials parameter blob for the specified region. To get the web service from a region other than the region in which it has been created, you must first call Create Regional Web Services Properties to create a copy of the encrypted credential parameter blob in that region. You only need to do this before the first time that you get the web service in the new region.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearning/webServices/{webServiceName}/CreateRegionalBlob
# operationId: WebServices_CreateRegionalProperties
export def "subscriptions-resource-groups-providers-microsoft-machine-learning-web-services-create-regional-blob CreateRegionalProperties" [
  resourceGroupName: string
  webServiceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --region: string # The region for which encrypted credential parameters are created.
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
]: nothing -> record<endTime: string, errorInfo: record<code: string, details: list<any>, message: string, target: string>, id: string, name: string, percentComplete: float, provisioningState: string, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearning/webServices/($webServiceName)/CreateRegionalBlob" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the access keys for the specified web service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.MachineLearning/webServices/{webServiceName}/listKeys
# operationId: WebServices_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-machine-learning-web-services-list-keys ListKeys" [
  resourceGroupName: string
  webServiceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the Microsoft.MachineLearning resource provider API to use.
]: nothing -> record<primary: string, secondary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.MachineLearning/webServices/($webServiceName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
