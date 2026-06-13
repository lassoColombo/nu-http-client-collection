# Auto-generated client for RemediationsClient v2019-07-01
# Source: https://api.apis.guru/v2/specs/azure.com/policyinsights-remediations/2019-07-01/swagger.json
# Auth: --token flag or $env.REMEDIATIONSCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REMEDIATIONSCLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-management-groups-providers-microsoft-policy-insights-remediations ListForManagementGroup" } } | get name | first)
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

# Gets all remediations for the management group.
#
# GET /providers/{managementGroupsNamespace}/managementGroups/{managementGroupId}/providers/Microsoft.PolicyInsights/remediations
# operationId: Remediations_ListForManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-remediations ListForManagementGroup" [
  managementGroupsNamespace: string
  managementGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Maximum number of records to return. (format: int32)
  --filter: string # OData filter expression.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($managementGroupsNamespace)/managementGroups/($managementGroupId)/providers/Microsoft.PolicyInsights/remediations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing remediation at management group scope.
#
# DELETE /providers/{managementGroupsNamespace}/managementGroups/{managementGroupId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_DeleteAtManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-remediations DeleteAtManagementGroup" [
  managementGroupsNamespace: string
  managementGroupId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($managementGroupsNamespace)/managementGroups/($managementGroupId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an existing remediation at management group scope.
#
# GET /providers/{managementGroupsNamespace}/managementGroups/{managementGroupId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_GetAtManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-remediations GetAtManagementGroup" [
  managementGroupsNamespace: string
  managementGroupId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($managementGroupsNamespace)/managementGroups/($managementGroupId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a remediation at management group scope.
#
# PUT /providers/{managementGroupsNamespace}/managementGroups/{managementGroupId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_CreateOrUpdateAtManagementGroup
# --properties shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
export def "providers-management-groups-providers-microsoft-policy-insights-remediations CreateOrUpdateAtManagementGroup" [
  managementGroupsNamespace: string
  managementGroupId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The remediation properties. — shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
]: any -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($managementGroupsNamespace)/managementGroups/($managementGroupId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a remediation at management group scope.
#
# POST /providers/{managementGroupsNamespace}/managementGroups/{managementGroupId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/cancel
# operationId: Remediations_CancelAtManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-remediations-cancel CancelAtManagementGroup" [
  managementGroupsNamespace: string
  managementGroupId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($managementGroupsNamespace)/managementGroups/($managementGroupId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments for a remediation at management group scope.
#
# POST /providers/{managementGroupsNamespace}/managementGroups/{managementGroupId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/listDeployments
# operationId: Remediations_ListDeploymentsAtManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-remediations-list-deployments ListDeploymentsAtManagementGroup" [
  managementGroupsNamespace: string
  managementGroupId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Maximum number of records to return. (format: int32)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<createdOn: string, deploymentId: string, error: record, lastUpdatedOn: string, remediatedResourceId: string, resourceLocation: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($managementGroupsNamespace)/managementGroups/($managementGroupId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/listDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all remediations for the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/remediations
# operationId: Remediations_ListForSubscription
export def "subscriptions-providers-microsoft-policy-insights-remediations ListForSubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Maximum number of records to return. (format: int32)
  --filter: string # OData filter expression.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.PolicyInsights/remediations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing remediation at subscription scope.
#
# DELETE /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_DeleteAtSubscription
export def "subscriptions-providers-microsoft-policy-insights-remediations DeleteAtSubscription" [
  subscriptionId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an existing remediation at subscription scope.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_GetAtSubscription
export def "subscriptions-providers-microsoft-policy-insights-remediations GetAtSubscription" [
  subscriptionId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a remediation at subscription scope.
#
# PUT /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_CreateOrUpdateAtSubscription
# --properties shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
export def "subscriptions-providers-microsoft-policy-insights-remediations CreateOrUpdateAtSubscription" [
  subscriptionId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The remediation properties. — shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
]: any -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a remediation at subscription scope.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/cancel
# operationId: Remediations_CancelAtSubscription
export def "subscriptions-providers-microsoft-policy-insights-remediations-cancel CancelAtSubscription" [
  subscriptionId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments for a remediation at subscription scope.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/listDeployments
# operationId: Remediations_ListDeploymentsAtSubscription
export def "subscriptions-providers-microsoft-policy-insights-remediations-list-deployments ListDeploymentsAtSubscription" [
  subscriptionId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Maximum number of records to return. (format: int32)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<createdOn: string, deploymentId: string, error: record, lastUpdatedOn: string, remediatedResourceId: string, resourceLocation: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/listDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all remediations for the subscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/remediations
# operationId: Remediations_ListForResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-remediations ListForResourceGroup" [
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
  --top: int # Maximum number of records to return. (format: int32)
  --filter: string # OData filter expression.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.PolicyInsights/remediations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing remediation at resource group scope.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_DeleteAtResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-remediations DeleteAtResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an existing remediation at resource group scope.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_GetAtResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-remediations GetAtResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a remediation at resource group scope.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_CreateOrUpdateAtResourceGroup
# --properties shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-remediations CreateOrUpdateAtResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The remediation properties. — shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
]: any -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels a remediation at resource group scope.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/cancel
# operationId: Remediations_CancelAtResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-remediations-cancel CancelAtResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments for a remediation at resource group scope.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/listDeployments
# operationId: Remediations_ListDeploymentsAtResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-remediations-list-deployments ListDeploymentsAtResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Maximum number of records to return. (format: int32)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<createdOn: string, deploymentId: string, error: record, lastUpdatedOn: string, remediatedResourceId: string, resourceLocation: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/listDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all remediations for a resource.
#
# GET /{resourceId}/providers/Microsoft.PolicyInsights/remediations
# operationId: Remediations_ListForResource
export def "providers-microsoft-policy-insights-remediations ListForResource" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Maximum number of records to return. (format: int32)
  --filter: string # OData filter expression.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)/providers/Microsoft.PolicyInsights/remediations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing remediation at individual resource scope.
#
# DELETE /{resourceId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_DeleteAtResource
export def "providers-microsoft-policy-insights-remediations DeleteAtResource" [
  resourceId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an existing remediation at resource scope.
#
# GET /{resourceId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_GetAtResource
export def "providers-microsoft-policy-insights-remediations GetAtResource" [
  resourceId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a remediation at resource scope.
#
# PUT /{resourceId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}
# operationId: Remediations_CreateOrUpdateAtResource
# --properties shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
export def "providers-microsoft-policy-insights-remediations CreateOrUpdateAtResource" [
  resourceId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The remediation properties. — shape: {deploymentStatus?: any, filters?: any, policyAssignmentId?: string, policyDefinitionReferenceId?: string, resourceDiscoveryMode?: "ExistingNonCompliant"|"ReEvaluateCompliance"}
]: any -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a remediation at resource scope.
#
# POST /{resourceId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/cancel
# operationId: Remediations_CancelAtResource
export def "providers-microsoft-policy-insights-remediations-cancel CancelAtResource" [
  resourceId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<createdOn: string, deploymentStatus: record<failedDeployments: int, successfulDeployments: int, totalDeployments: int>, filters: record<locations: list>, lastUpdatedOn: string, policyAssignmentId: string, policyDefinitionReferenceId: string, provisioningState: string, resourceDiscoveryMode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all deployments for a remediation at resource scope.
#
# POST /{resourceId}/providers/Microsoft.PolicyInsights/remediations/{remediationName}/listDeployments
# operationId: Remediations_ListDeploymentsAtResource
export def "providers-microsoft-policy-insights-remediations-list-deployments ListDeploymentsAtResource" [
  resourceId: string
  remediationName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Maximum number of records to return. (format: int32)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<createdOn: string, deploymentId: string, error: record, lastUpdatedOn: string, remediatedResourceId: string, resourceLocation: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)/providers/Microsoft.PolicyInsights/remediations/($remediationName)/listDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
