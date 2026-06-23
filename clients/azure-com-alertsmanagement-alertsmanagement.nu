# Auto-generated client for Azure Alerts Management Service Resource Provider v2019-05-05-preview
# Source: https://api.apis.guru/v2/specs/azure.com/alertsmanagement-AlertsManagement/2019-05-05-preview/swagger.json
# Auth: --token flag or $env.AZURE_ALERTS_MANAGEMENT_SERVICE_RESOURCE_PROVIDER_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_ALERTS_MANAGEMENT_SERVICE_RESOURCE_PROVIDER_TOKEN | default "" }
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

# Completers for enum parameters
def api-version-completer [] { ["2019-05-05-preview"] }
def identifier-completer [] { ["MonitorServiceList"] }
def severity-completer [] { ["Sev0" "Sev1" "Sev2" "Sev3" "Sev4"] }
def monitor-service-completer [] { ["ActivityLog Administrative" "ActivityLog Autoscale" "ActivityLog Policy" "ActivityLog Recommendation" "ActivityLog Security" "Application Insights" "Log Analytics" "Nagios" "Platform" "SCOM" "ServiceHealth" "SmartDetector" "VM Insights" "Zabbix"] }
def monitor-condition-completer [] { ["Fired" "Resolved"] }
def alert-state-completer [] { ["Acknowledged" "Closed" "New"] }
def sort-by-completer [] { ["alertState" "lastModifiedDateTime" "monitorCondition" "name" "severity" "startDateTime" "targetResource" "targetResourceGroup" "targetResourceName" "targetResourceType"] }
def sort-order-completer [] { ["asc" "desc"] }
def time-range-completer [] { ["1d" "1h" "30d" "7d"] }
def new-state-completer [] { ["Acknowledged" "Closed" "New"] }
def groupby-completer [] { ["alertRule" "alertState" "monitorCondition" "monitorService" "severity" "signalType"] }
def smart-group-state-completer [] { ["Acknowledged" "Closed" "New"] }
def sort-by-completer-1 [] { ["alertsCount" "lastModifiedDateTime" "severity" "startDateTime" "state"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-alerts-management-alerts-meta-data get" } } | get name | first)
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

# List alerts meta data information based on value of identifier parameter.
#
# GET /providers/Microsoft.AlertsManagement/alertsMetaData
# operationId: Alerts_MetaData
export def "providers-microsoft-alerts-management-alerts-meta-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
  --identifier: string@identifier-completer # Identification of the information to be retrieved by API call.
]: nothing -> record<properties: record<metadataIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.AlertsManagement/alertsMetaData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "identifier": $identifier} | compact), body: null}
}

# List all operations available through Azure Alerts Management Resource Provider.
#
# GET /providers/Microsoft.AlertsManagement/operations
# operationId: Operations_List
export def "providers-microsoft-alerts-management-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.AlertsManagement/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get all action rule in a given subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/actionRules
# operationId: ActionRules_ListBySubscription
export def "subscriptions-providers-microsoft-alerts-management-action-rules list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --impacted-scope: string # filter by impacted/target scope (provide comma separated list for multiple scopes). The value should be an well constructed ARM id of the scope.
  --description: string # filter by alert rule description
  --alert-rule-id: string # filter by alert rule id
  --action-group: string # filter by action group configured as part of action rule
  --name: string # filter by action rule name
  --api-version: string@api-version-completer # client API version
]: nothing -> record<nextLink: string, value: table<properties: record, location: string, tags: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "targetResourceGroup" $target_resource_group "scalar") (serialize-qp "targetResourceType" $target_resource_type "scalar") (serialize-qp "targetResource" $target_resource "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "monitorService" $monitor_service "scalar") (serialize-qp "impactedScope" $impacted_scope "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "alertRuleId" $alert_rule_id "scalar") (serialize-qp "actionGroup" $action_group "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/actionRules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"targetResourceGroup": $target_resource_group, "targetResourceType": $target_resource_type, "targetResource": $target_resource, "severity": $severity, "monitorService": $monitor_service, "impactedScope": $impacted_scope, "description": $description, "alertRuleId": $alert_rule_id, "actionGroup": $action_group, "name": $name, "api-version": $api_version} | compact), body: null}
}

# List all existing alerts, where the results can be filtered on the basis of multiple parameters (e.g. time range). The results can then be sorted on the basis specific fields, with the default being lastModifiedDateTime.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts
# operationId: Alerts_GetAll
export def "subscriptions-providers-microsoft-alerts-management-alerts get-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --monitor-condition: string@monitor-condition-completer # Filter by monitor condition which is either 'Fired' or 'Resolved'. Default value is to select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --alert-state: string@alert-state-completer # Filter by state of the alert instance. Default value is to select all.
  --alert-rule: string # Filter by specific alert rule. Default value is to select all.
  --smart-group-id: string # Filter the alerts list by the Smart Group Id. Default value is none.
  --include-context: oneof<nothing, bool> # Include context which has contextual data specific to the monitor service. Default value is false'
  --include-egress-config: oneof<nothing, bool> # Include egress config which would be used for displaying the content in portal. Default value is 'false'.
  --page-count: int # Determines number of alerts returned per page in response. Permissible value is between 1 to 250. When the "includeContent" filter is selected, maximum value allowed is 25. Default value is 25.
  --sort-by: string@sort-by-completer # Sort the query results by input field, Default value is 'lastModifiedDateTime'.
  --sort-order: string@sort-order-completer # Sort the query results order in either ascending or descending. Default value is 'desc' for time fields and 'asc' for others.
  --select: string # This filter allows to selection of the fields(comma separated) which would be part of the essential section. This would allow to project only the required fields rather than getting entire content. Default is to fetch all the fields in the essentials section.
  --time-range: string@time-range-completer # Filter by time range by below listed values. Default value is 1 day.
  --custom-time-range: string # Filter by custom time range in the format <start-time>/<end-time> where time is in (ISO-8601 format)'. Permissible values is within 30 days from query time. Either timeRange or customTimeRange could be used but not both. Default is none.
  --api-version: string@api-version-completer # client API version
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "targetResource" $target_resource "scalar") (serialize-qp "targetResourceType" $target_resource_type "scalar") (serialize-qp "targetResourceGroup" $target_resource_group "scalar") (serialize-qp "monitorService" $monitor_service "scalar") (serialize-qp "monitorCondition" $monitor_condition "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "alertState" $alert_state "scalar") (serialize-qp "alertRule" $alert_rule "scalar") (serialize-qp "smartGroupId" $smart_group_id "scalar") (serialize-qp "includeContext" $include_context "scalar") (serialize-qp "includeEgressConfig" $include_egress_config "scalar") (serialize-qp "pageCount" $page_count "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "select" $select "scalar") (serialize-qp "timeRange" $time_range "scalar") (serialize-qp "customTimeRange" $custom_time_range "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/alerts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"targetResource": $target_resource, "targetResourceType": $target_resource_type, "targetResourceGroup": $target_resource_group, "monitorService": $monitor_service, "monitorCondition": $monitor_condition, "severity": $severity, "alertState": $alert_state, "alertRule": $alert_rule, "smartGroupId": $smart_group_id, "includeContext": $include_context, "includeEgressConfig": $include_egress_config, "pageCount": $page_count, "sortBy": $sort_by, "sortOrder": $sort_order, "select": $select, "timeRange": $time_range, "customTimeRange": $custom_time_range, "api-version": $api_version} | compact), body: null}
}

# Get a specific alert.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}
# operationId: Alerts_GetById
export def "subscriptions-providers-microsoft-alerts-management-alerts get" [
  subscription_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
]: nothing -> record<properties: record<context: record, egressConfig: record, essentials: record<alertRule: string, alertState: string, lastModifiedDateTime: string, lastModifiedUserName: string, monitorCondition: string, monitorConditionResolvedDateTime: string, monitorService: string, severity: string, signalType: string, smartGroupId: string, smartGroupingReason: string, sourceCreatedId: string, startDateTime: string, targetResource: string, targetResourceGroup: string, targetResourceName: string, targetResourceType: string>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alertId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/alerts/{alert_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Change the state of an alert.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}/changestate
# operationId: Alerts_ChangeState
export def "subscriptions-providers-microsoft-alerts-management-alerts-changestate create-change-state" [
  subscription_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
  --new-state: string@new-state-completer # New state of the alert.
]: nothing -> record<properties: record<context: record, egressConfig: record, essentials: record<alertRule: string, alertState: string, lastModifiedDateTime: string, lastModifiedUserName: string, monitorCondition: string, monitorConditionResolvedDateTime: string, monitorService: string, severity: string, signalType: string, smartGroupId: string, smartGroupingReason: string, sourceCreatedId: string, startDateTime: string, targetResource: string, targetResourceGroup: string, targetResourceName: string, targetResourceType: string>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alertId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "newState" $new_state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/alerts/{alert_id}/changestate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "newState": $new_state} | compact), body: null}
}

# Get the history of an alert, which captures any monitor condition changes (Fired/Resolved) and alert state changes (New/Acknowledged/Closed).
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alerts/{alertId}/history
# operationId: Alerts_GetHistory
export def "subscriptions-providers-microsoft-alerts-management-alerts-history get" [
  subscription_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
]: nothing -> record<properties: record<alertId: string, modifications: list<record>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alertId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/alerts/{alert_id}/history") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get a summarized count of your alerts grouped by various parameters (e.g. grouping by 'Severity' returns the count of alerts for each severity).
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/alertsSummary
# operationId: Alerts_GetSummary
export def "subscriptions-providers-microsoft-alerts-management-alerts-summary get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupby: string@groupby-completer # This parameter allows the result set to be grouped by input fields (Maximum 2 comma separated fields supported). For example, groupby=severity or groupby=severity,alertstate.
  --include-smart-groups-count: oneof<nothing, bool> # Include count of the SmartGroups as part of the summary. Default value is 'false'.
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --monitor-condition: string@monitor-condition-completer # Filter by monitor condition which is either 'Fired' or 'Resolved'. Default value is to select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --alert-state: string@alert-state-completer # Filter by state of the alert instance. Default value is to select all.
  --alert-rule: string # Filter by specific alert rule. Default value is to select all.
  --time-range: string@time-range-completer # Filter by time range by below listed values. Default value is 1 day.
  --custom-time-range: string # Filter by custom time range in the format <start-time>/<end-time> where time is in (ISO-8601 format)'. Permissible values is within 30 days from query time. Either timeRange or customTimeRange could be used but not both. Default is none.
  --api-version: string@api-version-completer # client API version
]: nothing -> record<properties: record<groupedby: string, smartGroupsCount: int, total: int, values: list<record>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "groupby" $groupby "scalar") (serialize-qp "includeSmartGroupsCount" $include_smart_groups_count "scalar") (serialize-qp "targetResource" $target_resource "scalar") (serialize-qp "targetResourceType" $target_resource_type "scalar") (serialize-qp "targetResourceGroup" $target_resource_group "scalar") (serialize-qp "monitorService" $monitor_service "scalar") (serialize-qp "monitorCondition" $monitor_condition "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "alertState" $alert_state "scalar") (serialize-qp "alertRule" $alert_rule "scalar") (serialize-qp "timeRange" $time_range "scalar") (serialize-qp "customTimeRange" $custom_time_range "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/alertsSummary") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"groupby": $groupby, "includeSmartGroupsCount": $include_smart_groups_count, "targetResource": $target_resource, "targetResourceType": $target_resource_type, "targetResourceGroup": $target_resource_group, "monitorService": $monitor_service, "monitorCondition": $monitor_condition, "severity": $severity, "alertState": $alert_state, "alertRule": $alert_rule, "timeRange": $time_range, "customTimeRange": $custom_time_range, "api-version": $api_version} | compact), body: null}
}

# Get all Smart Groups within a specified subscription
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups
# operationId: SmartGroups_GetAll
export def "subscriptions-providers-microsoft-alerts-management-smart-groups get-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --monitor-condition: string@monitor-condition-completer # Filter by monitor condition which is either 'Fired' or 'Resolved'. Default value is to select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --smart-group-state: string@smart-group-state-completer # Filter by state of the smart group. Default value is to select all.
  --time-range: string@time-range-completer # Filter by time range by below listed values. Default value is 1 day.
  --page-count: int # Determines number of alerts returned per page in response. Permissible value is between 1 to 250. When the "includeContent" filter is selected, maximum value allowed is 25. Default value is 25.
  --sort-by: string@sort-by-completer-1 # Sort the query results by input field. Default value is sort by 'lastModifiedDateTime'.
  --sort-order: string@sort-order-completer # Sort the query results order in either ascending or descending. Default value is 'desc' for time fields and 'asc' for others.
  --api-version: string@api-version-completer # client API version
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "targetResource" $target_resource "scalar") (serialize-qp "targetResourceGroup" $target_resource_group "scalar") (serialize-qp "targetResourceType" $target_resource_type "scalar") (serialize-qp "monitorService" $monitor_service "scalar") (serialize-qp "monitorCondition" $monitor_condition "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "smartGroupState" $smart_group_state "scalar") (serialize-qp "timeRange" $time_range "scalar") (serialize-qp "pageCount" $page_count "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/smartGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"targetResource": $target_resource, "targetResourceGroup": $target_resource_group, "targetResourceType": $target_resource_type, "monitorService": $monitor_service, "monitorCondition": $monitor_condition, "severity": $severity, "smartGroupState": $smart_group_state, "timeRange": $time_range, "pageCount": $page_count, "sortBy": $sort_by, "sortOrder": $sort_order, "api-version": $api_version} | compact), body: null}
}

# Get information related to a specific Smart Group.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}
# operationId: SmartGroups_GetById
export def "subscriptions-providers-microsoft-alerts-management-smart-groups get" [
  subscription_id: string
  smart_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
]: nothing -> record<properties: record<alertSeverities: list<record>, alertStates: list<record>, alertsCount: int, lastModifiedDateTime: string, lastModifiedUserName: string, monitorConditions: list<record>, monitorServices: list<record>, nextLink: string, resourceGroups: list<record>, resourceTypes: list<record>, resources: list<record>, severity: string, smartGroupState: string, startDateTime: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($smart_group_id | is-empty) { error make --unspanned { msg: "path parameter 'smartGroupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), smart_group_id: (encode-path-segment $smart_group_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/smartGroups/{smart_group_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Change the state of a Smart Group.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}/changeState
# operationId: SmartGroups_ChangeState
export def "subscriptions-providers-microsoft-alerts-management-smart-groups-change-state create" [
  subscription_id: string
  smart_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
  --new-state: string@new-state-completer # New state of the alert.
]: nothing -> record<properties: record<alertSeverities: list<record>, alertStates: list<record>, alertsCount: int, lastModifiedDateTime: string, lastModifiedUserName: string, monitorConditions: list<record>, monitorServices: list<record>, nextLink: string, resourceGroups: list<record>, resourceTypes: list<record>, resources: list<record>, severity: string, smartGroupState: string, startDateTime: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($smart_group_id | is-empty) { error make --unspanned { msg: "path parameter 'smartGroupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "newState" $new_state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), smart_group_id: (encode-path-segment $smart_group_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/smartGroups/{smart_group_id}/changeState") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "newState": $new_state} | compact), body: null}
}

# Get the history a smart group, which captures any Smart Group state changes (New/Acknowledged/Closed) .
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AlertsManagement/smartGroups/{smartGroupId}/history
# operationId: SmartGroups_GetHistory
export def "subscriptions-providers-microsoft-alerts-management-smart-groups-history get" [
  subscription_id: string
  smart_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
]: nothing -> record<properties: record<modifications: list<record>, nextLink: string, smartGroupId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($smart_group_id | is-empty) { error make --unspanned { msg: "path parameter 'smartGroupId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), smart_group_id: (encode-path-segment $smart_group_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AlertsManagement/smartGroups/{smart_group_id}/history") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get all action rules created in a resource group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules
# operationId: ActionRules_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-alerts-management-action-rules list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-resource-group: string # Filter by target resource group name. Default value is select all.
  --target-resource-type: string # Filter by target resource type. Default value is select all.
  --target-resource: string # Filter by target resource( which is full ARM ID) Default value is select all.
  --severity: string@severity-completer # Filter by severity. Default value is select all.
  --monitor-service: string@monitor-service-completer # Filter by monitor service which generates the alert instance. Default value is select all.
  --impacted-scope: string # filter by impacted/target scope (provide comma separated list for multiple scopes). The value should be an well constructed ARM id of the scope.
  --description: string # filter by alert rule description
  --alert-rule-id: string # filter by alert rule id
  --action-group: string # filter by action group configured as part of action rule
  --name: string # filter by action rule name
  --api-version: string@api-version-completer # client API version
]: nothing -> record<nextLink: string, value: table<properties: record, location: string, tags: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "targetResourceGroup" $target_resource_group "scalar") (serialize-qp "targetResourceType" $target_resource_type "scalar") (serialize-qp "targetResource" $target_resource "scalar") (serialize-qp "severity" $severity "scalar") (serialize-qp "monitorService" $monitor_service "scalar") (serialize-qp "impactedScope" $impacted_scope "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "alertRuleId" $alert_rule_id "scalar") (serialize-qp "actionGroup" $action_group "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AlertsManagement/actionRules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"targetResourceGroup": $target_resource_group, "targetResourceType": $target_resource_type, "targetResource": $target_resource, "severity": $severity, "monitorService": $monitor_service, "impactedScope": $impacted_scope, "description": $description, "alertRuleId": $alert_rule_id, "actionGroup": $action_group, "name": $name, "api-version": $api_version} | compact), body: null}
}

# Delete action rule
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# operationId: ActionRules_Delete
export def "subscriptions-resource-groups-providers-microsoft-alerts-management-action-rules delete" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($action_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'actionRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), action_rule_name: (encode-path-segment $action_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AlertsManagement/actionRules/{action_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get action rule by name
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# operationId: ActionRules_GetByName
export def "subscriptions-resource-groups-providers-microsoft-alerts-management-action-rules get-by-name" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
]: nothing -> record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($action_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'actionRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), action_rule_name: (encode-path-segment $action_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AlertsManagement/actionRules/{action_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Patch action rule
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# operationId: ActionRules_Update
# --properties shape: {status?: "Enabled"|"Disabled"}
export def "subscriptions-resource-groups-providers-microsoft-alerts-management-action-rules update" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
  --properties: any # Action rule properties supported by patch — shape: {status?: "Enabled"|"Disabled"}
  --tags: record # tags to be updated
]: any -> record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($action_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'actionRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), action_rule_name: (encode-path-segment $action_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AlertsManagement/actionRules/{action_rule_name}") $qp)
  let req_body = {"properties": $properties, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Create/update an action rule
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AlertsManagement/actionRules/{actionRuleName}
# operationId: ActionRules_CreateUpdate
# --properties shape: {conditions?: record, description?: string, scope?: record, status?: "Enabled"|"Disabled", type: "Suppression"|"ActionGroup"|"Diagnostics"}
export def "subscriptions-resource-groups-providers-microsoft-alerts-management-action-rules create-update" [
  subscription_id: string
  resource_group_name: string
  action_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # client API version
  --properties: any # Action rule properties defining scope, conditions, suppression logic for action rule — shape: {conditions?: record, description?: string, scope?: record, status?: "Enabled"|"Disabled", type: "Suppression"|"ActionGroup"|"Diagnostics"}
  location: string # Resource location
  --tags: any # Resource tags
]: any -> record<properties: record<conditions: record<alertContext: record, alertRuleId: record, description: record, monitorCondition: record, monitorService: record, severity: record, targetResourceType: record>, createdAt: string, createdBy: string, description: string, lastModifiedAt: string, lastModifiedBy: string, scope: record<scopeType: string, values: list>, status: string, type: string>, location: string, tags: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($action_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'actionRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), action_rule_name: (encode-path-segment $action_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AlertsManagement/actionRules/{action_rule_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
