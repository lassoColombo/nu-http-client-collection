# Auto-generated client for PolicyEventsClient v2018-04-04
# Source: https://api.apis.guru/v2/specs/azure.com/policyinsights-policyEvents/2018-04-04/swagger.json
# Auth: --token flag or $env.POLICYEVENTSCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POLICYEVENTSCLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-management-groups-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForManagementGroup" } } | get name | first)
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

# Queries policy events for the resources under the management group.
#
# POST /providers/{managementGroupsNamespace}/managementGroups/{managementGroupName}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForManagementGroup" [
  policyEventsResource: string
  managementGroupsNamespace: string
  managementGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/providers/($managementGroupsNamespace)/managementGroups/($managementGroupName)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries policy events for the resources under the subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForSubscription
export def "subscriptions-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForSubscription" [
  policyEventsResource: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries policy events for the subscription level policy assignment.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policyAssignments/{policyAssignmentName}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForSubscriptionLevelPolicyAssignment
export def "subscriptions-providers-policy-assignments-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForSubscriptionLevelPolicyAssignment" [
  policyEventsResource: string
  subscriptionId: string
  authorizationNamespace: string
  policyAssignmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/($authorizationNamespace)/policyAssignments/($policyAssignmentName)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries policy events for the subscription level policy definition.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policyDefinitions/{policyDefinitionName}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForPolicyDefinition
export def "subscriptions-providers-policy-definitions-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForPolicyDefinition" [
  policyEventsResource: string
  subscriptionId: string
  authorizationNamespace: string
  policyDefinitionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/($authorizationNamespace)/policyDefinitions/($policyDefinitionName)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries policy events for the subscription level policy set definition.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policySetDefinitions/{policySetDefinitionName}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForPolicySetDefinition
export def "subscriptions-providers-policy-set-definitions-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForPolicySetDefinition" [
  policyEventsResource: string
  subscriptionId: string
  authorizationNamespace: string
  policySetDefinitionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/($authorizationNamespace)/policySetDefinitions/($policySetDefinitionName)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries policy events for the resources under the resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForResourceGroup" [
  policyEventsResource: string
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
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries policy events for the resource group level policy assignment.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{authorizationNamespace}/policyAssignments/{policyAssignmentName}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForResourceGroupLevelPolicyAssignment
export def "subscriptions-resourcegroups-providers-policy-assignments-providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForResourceGroupLevelPolicyAssignment" [
  policyEventsResource: string
  subscriptionId: string
  resourceGroupName: string
  authorizationNamespace: string
  policyAssignmentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourcegroups/($resourceGroupName)/providers/($authorizationNamespace)/policyAssignments/($policyAssignmentName)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries policy events for the resource.
#
# POST /{resourceId}/providers/Microsoft.PolicyInsights/policyEvents/{policyEventsResource}/queryResults
# operationId: PolicyEvents_ListQueryResultsForResource
export def "providers-microsoft-policy-insights-policy-events-query-results ListQueryResultsForResource" [
  policyEventsResource: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, principalOid: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, tenantId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($resourceId)/providers/Microsoft.PolicyInsights/policyEvents/($policyEventsResource)/queryResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets OData metadata XML document.
#
# GET /{scope}/providers/Microsoft.PolicyInsights/policyEvents/$metadata
# operationId: PolicyEvents_GetMetadata
export def "providers-microsoft-policy-insights-policy-events-metadata GetMetadata" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version to use with the client requests.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($scope)/providers/Microsoft.PolicyInsights/policyEvents/$metadata" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
