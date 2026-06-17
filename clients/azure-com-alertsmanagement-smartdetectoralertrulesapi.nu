# Auto-generated client for Azure Alerts Management Service Resource Provider v2019-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/alertsmanagement-SmartDetectorAlertRulesApi/2019-06-01/swagger.json
# Auth: --token flag or $env.AZURE_ALERTS_MANAGEMENT_SERVICE_RESOURCE_PROVIDER_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_ALERTS_MANAGEMENT_SERVICE_RESOURCE_PROVIDER_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoftalerts-management-smart-detector-alert-rules list" } } | get name | first)
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

# List all the existing Smart Detector alert rules within the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/microsoft.alertsManagement/smartDetectorAlertRules
# operationId: SmartDetectorAlertRules_List
export def "subscriptions-providers-microsoftalerts-management-smart-detector-alert-rules list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --expand-detector: oneof<nothing, bool> # Indicates if Smart Detector should be expanded.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "expandDetector" $expand_detector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/subscriptions/{subscription_id}/providers/microsoft.alertsManagement/smartDetectorAlertRules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the existing Smart Detector alert rules within the subscription and resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.alertsManagement/smartDetectorAlertRules
# operationId: SmartDetectorAlertRules_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoftalerts-management-smart-detector-alert-rules list-by" [
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
  --api-version: string # Client Api Version.
  --expand-detector: oneof<nothing, bool> # Indicates if Smart Detector should be expanded.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "expandDetector" $expand_detector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/microsoft.alertsManagement/smartDetectorAlertRules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing Smart Detector alert rule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alertRuleName}
# operationId: SmartDetectorAlertRules_Delete
export def "subscriptions-resource-groups-providers-microsoftalerts-management-smart-detector-alert-rules delete" [
  subscription_id: string
  resource_group_name: string
  alert_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, alert_rule_name: $alert_rule_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alert_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Smart Detector alert rule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alertRuleName}
# operationId: SmartDetectorAlertRules_Get
export def "subscriptions-resource-groups-providers-microsoftalerts-management-smart-detector-alert-rules get" [
  subscription_id: string
  resource_group_name: string
  alert_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --expand-detector: oneof<nothing, bool> # Indicates if Smart Detector should be expanded.
]: nothing -> record<properties: record<actionGroups: record<customEmailSubject: string, customWebhookPayload: string, groupIds: list>, description: string, detector: record<description: string, id: string, imagePaths: list, name: string, parameters: record, supportedResourceTypes: list>, frequency: string, scope: list<string>, severity: string, state: string, throttling: record<duration: string>>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "expandDetector" $expand_detector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, alert_rule_name: $alert_rule_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alert_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a specific Smart Detector alert rule.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alertRuleName}
# operationId: SmartDetectorAlertRules_Patch
# --properties shape: {actionGroups?: any, description?: string, frequency?: string, severity?: "Sev0"|"Sev1"|"Sev2"|"Sev3"|"Sev4", state?: "Enabled"|"Disabled", throttling?: any}
export def "subscriptions-resource-groups-providers-microsoftalerts-management-smart-detector-alert-rules update" [
  subscription_id: string
  resource_group_name: string
  alert_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The alert rule properties. — shape: {actionGroups?: any, description?: string, frequency?: string, severity?: "Sev0"|"Sev1"|"Sev2"|"Sev3"|"Sev4", state?: "Enabled"|"Disabled", throttling?: any}
  --tags: record # The resource tags.
]: any -> record<properties: record<actionGroups: record<customEmailSubject: string, customWebhookPayload: string, groupIds: list>, description: string, detector: record<description: string, id: string, imagePaths: list, name: string, parameters: record, supportedResourceTypes: list>, frequency: string, scope: list<string>, severity: string, state: string, throttling: record<duration: string>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, alert_rule_name: $alert_rule_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alert_rule_name}") $qp)
  let body = {"properties": $properties, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create or update a Smart Detector alert rule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alertRuleName}
# operationId: SmartDetectorAlertRules_CreateOrUpdate
# --properties shape: {actionGroups: any, description?: string, detector: any, frequency: string, scope: list, severity: "Sev0"|"Sev1"|"Sev2"|"Sev3"|"Sev4", state: "Enabled"|"Disabled", throttling?: any}
export def "subscriptions-resource-groups-providers-microsoftalerts-management-smart-detector-alert-rules create-or-update" [
  subscription_id: string
  resource_group_name: string
  alert_rule_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: any # The alert rule properties. — shape: {actionGroups: any, description?: string, detector: any, frequency: string, scope: list, severity: "Sev0"|"Sev1"|"Sev2"|"Sev3"|"Sev4", state: "Enabled"|"Disabled", throttling?: any}
  --location: string # The resource location. (default: global)
  --tags: record # The resource tags.
]: any -> record<properties: record<actionGroups: record<customEmailSubject: string, customWebhookPayload: string, groupIds: list>, description: string, detector: record<description: string, id: string, imagePaths: list, name: string, parameters: record, supportedResourceTypes: list>, frequency: string, scope: list<string>, severity: string, state: string, throttling: record<duration: string>>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, alert_rule_name: $alert_rule_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/microsoft.alertsManagement/smartDetectorAlertRules/{alert_rule_name}") $qp)
  let body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
