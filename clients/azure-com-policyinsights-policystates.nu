# Auto-generated client for PolicyStatesClient v2018-07-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/policyinsights-policyStates/2018-07-01-preview/swagger.json
# Auth: --token flag or $env.POLICYSTATESCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POLICYSTATESCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-policy-insights-operations list" } } | get name | first)
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

# Lists available operations.
#
# GET /providers/Microsoft.PolicyInsights/operations
# operationId: Operations_List
export def "providers-microsoft-policy-insights-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<_odata_count: int, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.PolicyInsights/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Queries policy states for the resources under the management group.
#
# POST /providers/{managementGroupsNamespace}/managementGroups/{managementGroupName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-policy-states-query-results list" [
  management_groups_namespace: string
  management_group_name: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($management_groups_namespace | is-empty) { error make --unspanned { msg: "path parameter 'managementGroupsNamespace' must be non-empty" } }
  if ($management_group_name | is-empty) { error make --unspanned { msg: "path parameter 'managementGroupName' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({management_groups_namespace: (encode-path-segment $management_groups_namespace), management_group_name: (encode-path-segment $management_group_name), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/providers/{management_groups_namespace}/managementGroups/{management_group_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply} | compact), body: null}
}

# Summarizes policy states for the resources under the management group.
#
# POST /providers/{managementGroupsNamespace}/managementGroups/{managementGroupName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForManagementGroup
export def "providers-management-groups-providers-microsoft-policy-insights-policy-states-summarize create" [
  management_groups_namespace: string
  management_group_name: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($management_groups_namespace | is-empty) { error make --unspanned { msg: "path parameter 'managementGroupsNamespace' must be non-empty" } }
  if ($management_group_name | is-empty) { error make --unspanned { msg: "path parameter 'managementGroupName' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({management_groups_namespace: (encode-path-segment $management_groups_namespace), management_group_name: (encode-path-segment $management_group_name), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/providers/{management_groups_namespace}/managementGroups/{management_group_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Queries policy states for the resources under the subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForSubscription
export def "subscriptions-providers-microsoft-policy-insights-policy-states-query-results list" [
  subscription_id: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply} | compact), body: null}
}

# Summarizes policy states for the resources under the subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForSubscription
export def "subscriptions-providers-microsoft-policy-insights-policy-states-summarize create" [
  subscription_id: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Queries policy states for the subscription level policy assignment.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policyAssignments/{policyAssignmentName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForSubscriptionLevelPolicyAssignment
export def "subscriptions-providers-policy-assignments-providers-microsoft-policy-insights-policy-states-query-results list-for-level" [
  subscription_id: string
  authorization_namespace: string
  policy_assignment_name: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_assignment_name | is-empty) { error make --unspanned { msg: "path parameter 'policyAssignmentName' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), authorization_namespace: (encode-path-segment $authorization_namespace), policy_assignment_name: (encode-path-segment $policy_assignment_name), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/subscriptions/{subscription_id}/providers/{authorization_namespace}/policyAssignments/{policy_assignment_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply} | compact), body: null}
}

# Summarizes policy states for the subscription level policy assignment.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policyAssignments/{policyAssignmentName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForSubscriptionLevelPolicyAssignment
export def "subscriptions-providers-policy-assignments-providers-microsoft-policy-insights-policy-states-summarize create-for-level" [
  subscription_id: string
  authorization_namespace: string
  policy_assignment_name: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_assignment_name | is-empty) { error make --unspanned { msg: "path parameter 'policyAssignmentName' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), authorization_namespace: (encode-path-segment $authorization_namespace), policy_assignment_name: (encode-path-segment $policy_assignment_name), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/subscriptions/{subscription_id}/providers/{authorization_namespace}/policyAssignments/{policy_assignment_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Queries policy states for the subscription level policy definition.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policyDefinitions/{policyDefinitionName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForPolicyDefinition
export def "subscriptions-providers-policy-definitions-providers-microsoft-policy-insights-policy-states-query-results list" [
  subscription_id: string
  authorization_namespace: string
  policy_definition_name: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'policyDefinitionName' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), authorization_namespace: (encode-path-segment $authorization_namespace), policy_definition_name: (encode-path-segment $policy_definition_name), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/subscriptions/{subscription_id}/providers/{authorization_namespace}/policyDefinitions/{policy_definition_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply} | compact), body: null}
}

# Summarizes policy states for the subscription level policy definition.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policyDefinitions/{policyDefinitionName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForPolicyDefinition
export def "subscriptions-providers-policy-definitions-providers-microsoft-policy-insights-policy-states-summarize create" [
  subscription_id: string
  authorization_namespace: string
  policy_definition_name: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'policyDefinitionName' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), authorization_namespace: (encode-path-segment $authorization_namespace), policy_definition_name: (encode-path-segment $policy_definition_name), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/subscriptions/{subscription_id}/providers/{authorization_namespace}/policyDefinitions/{policy_definition_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Queries policy states for the subscription level policy set definition.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policySetDefinitions/{policySetDefinitionName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForPolicySetDefinition
export def "subscriptions-providers-policy-set-definitions-providers-microsoft-policy-insights-policy-states-query-results list" [
  subscription_id: string
  authorization_namespace: string
  policy_set_definition_name: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_set_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'policySetDefinitionName' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), authorization_namespace: (encode-path-segment $authorization_namespace), policy_set_definition_name: (encode-path-segment $policy_set_definition_name), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/subscriptions/{subscription_id}/providers/{authorization_namespace}/policySetDefinitions/{policy_set_definition_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply} | compact), body: null}
}

# Summarizes policy states for the subscription level policy set definition.
#
# POST /subscriptions/{subscriptionId}/providers/{authorizationNamespace}/policySetDefinitions/{policySetDefinitionName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForPolicySetDefinition
export def "subscriptions-providers-policy-set-definitions-providers-microsoft-policy-insights-policy-states-summarize update" [
  subscription_id: string
  authorization_namespace: string
  policy_set_definition_name: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_set_definition_name | is-empty) { error make --unspanned { msg: "path parameter 'policySetDefinitionName' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), authorization_namespace: (encode-path-segment $authorization_namespace), policy_set_definition_name: (encode-path-segment $policy_set_definition_name), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/subscriptions/{subscription_id}/providers/{authorization_namespace}/policySetDefinitions/{policy_set_definition_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Queries policy states for the resources under the resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-policy-states-query-results list" [
  subscription_id: string
  resource_group_name: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply} | compact), body: null}
}

# Summarizes policy states for the resources under the resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-policy-insights-policy-states-summarize create" [
  subscription_id: string
  resource_group_name: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Queries policy states for the resource group level policy assignment.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{authorizationNamespace}/policyAssignments/{policyAssignmentName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForResourceGroupLevelPolicyAssignment
export def "subscriptions-resourcegroups-providers-policy-assignments-providers-microsoft-policy-insights-policy-states-query-results list-for-resource-group-level" [
  subscription_id: string
  resource_group_name: string
  authorization_namespace: string
  policy_assignment_name: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_assignment_name | is-empty) { error make --unspanned { msg: "path parameter 'policyAssignmentName' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), authorization_namespace: (encode-path-segment $authorization_namespace), policy_assignment_name: (encode-path-segment $policy_assignment_name), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/{authorization_namespace}/policyAssignments/{policy_assignment_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply} | compact), body: null}
}

# Summarizes policy states for the resource group level policy assignment.
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/{authorizationNamespace}/policyAssignments/{policyAssignmentName}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForResourceGroupLevelPolicyAssignment
export def "subscriptions-resourcegroups-providers-policy-assignments-providers-microsoft-policy-insights-policy-states-summarize create-for-resource-group-level" [
  subscription_id: string
  resource_group_name: string
  authorization_namespace: string
  policy_assignment_name: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($authorization_namespace | is-empty) { error make --unspanned { msg: "path parameter 'authorizationNamespace' must be non-empty" } }
  if ($policy_assignment_name | is-empty) { error make --unspanned { msg: "path parameter 'policyAssignmentName' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), authorization_namespace: (encode-path-segment $authorization_namespace), policy_assignment_name: (encode-path-segment $policy_assignment_name), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/{authorization_namespace}/policyAssignments/{policy_assignment_name}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Queries policy states for the resource.
#
# POST /{resourceId}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesResource}/queryResults
# operationId: PolicyStates_ListQueryResultsForResource
export def "providers-microsoft-policy-insights-policy-states-query-results list-for-resource" [
  resource_id: string
  policy_states_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --orderby: string # Ordering expression using OData notation. One or more comma-separated column names with an optional "desc" (the default) or "asc", e.g. "$orderby=PolicyAssignmentId, ResourceId asc".
  --select: string # Select expression using OData notation. Limits the columns on each record to just those requested, e.g. "$select=PolicyAssignmentId, ResourceId".
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
  --apply: string # OData apply expression for aggregations.
  --expand: string # The $expand query parameter. For example, to expand policyEvaluationDetails, use $expand=policyEvaluationDetails
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, complianceState: string, effectiveParameters: string, isCompliant: bool, managementGroupIds: string, policyAssignmentId: string, policyAssignmentName: string, policyAssignmentOwner: string, policyAssignmentParameters: string, policyAssignmentScope: string, policyDefinitionAction: string, policyDefinitionCategory: string, policyDefinitionId: string, policyDefinitionName: string, policyDefinitionReferenceId: string, policyEvaluationDetails: record, policySetDefinitionCategory: string, policySetDefinitionId: string, policySetDefinitionName: string, policySetDefinitionOwner: string, policySetDefinitionParameters: string, resourceGroup: string, resourceId: string, resourceLocation: string, resourceTags: string, resourceType: string, subscriptionId: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  if ($policy_states_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id), policy_states_resource: (encode-path-segment $policy_states_resource)} | format pattern "/{resource_id}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_resource}/queryResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$orderby": $orderby, "$select": $select, "$from": $qp_from, "$to": $qp_to, "$filter": $filter, "$apply": $apply, "$expand": $expand} | compact), body: null}
}

# Summarizes policy states for the resource.
#
# POST /{resourceId}/providers/Microsoft.PolicyInsights/policyStates/{policyStatesSummaryResource}/summarize
# operationId: PolicyStates_SummarizeForResource
export def "providers-microsoft-policy-insights-policy-states-summarize create-for-resource" [
  resource_id: string
  policy_states_summary_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --top: int # Maximum number of records to return. (format: int32)
  --qp-from: string # ISO 8601 formatted timestamp specifying the start time of the interval to query. When not specified, the service uses ($to - 1-day). (format: date-time)
  --qp-to: string # ISO 8601 formatted timestamp specifying the end time of the interval to query. When not specified, the service uses request time. (format: date-time)
  --filter: string # OData filter expression.
]: nothing -> record<_odata_context: string, _odata_count: int, value: table<_odata_context: string, _odata_id: string, policyAssignments: list, results: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceId' must be non-empty" } }
  if ($policy_states_summary_resource | is-empty) { error make --unspanned { msg: "path parameter 'policyStatesSummaryResource' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$from" $qp_from "scalar") (serialize-qp "$to" $qp_to "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id), policy_states_summary_resource: (encode-path-segment $policy_states_summary_resource)} | format pattern "/{resource_id}/providers/Microsoft.PolicyInsights/policyStates/{policy_states_summary_resource}/summarize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$top": $top, "$from": $qp_from, "$to": $qp_to, "$filter": $filter} | compact), body: null}
}

# Gets OData metadata XML document.
#
# GET /{scope}/providers/Microsoft.PolicyInsights/policyStates/$metadata
# operationId: PolicyStates_GetMetadata
export def "providers-microsoft-policy-insights-policy-states-metadata get-metadata" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/{scope}/providers/Microsoft.PolicyInsights/policyStates/$metadata") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}
