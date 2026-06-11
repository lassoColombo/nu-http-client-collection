# Auto-generated client for CustomerInsightsManagementClient v2017-04-26
# Source: https://api.apis.guru/v2/specs/azure.com/customer-insights/2017-04-26/swagger.json
# Auth: --token flag or $env.CUSTOMERINSIGHTSMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CUSTOMERINSIGHTSMANAGEMENTCLIENT_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["Active" "Deleted" "Discovering" "Evaluating" "EvaluatingFailed" "Failed" "Featuring" "FeaturingFailed" "HumanIntervention" "New" "PendingDiscovering" "PendingFeaturing" "PendingModelConfirmation" "PendingTraining" "Provisioning" "ProvisioningFailed" "Training" "TrainingFailed"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-customer-insights-operations List" } } | get name | first)
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

# Lists all of the available Customer Insights REST API operations.
#
# GET /providers/Microsoft.CustomerInsights/operations
# operationId: Operations_List
export def "providers-microsoft-customer-insights-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.CustomerInsights/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all hubs in the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.CustomerInsights/hubs
# operationId: Hubs_List
export def "subscriptions-providers-microsoft-customer-insights-hubs List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.CustomerInsights/hubs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all the hubs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs
# operationId: Hubs_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs ListByResourceGroup" [
  resourceGroupName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the specified hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs Delete" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs Get" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a Hub.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_Update
# --properties shape: {hubBillingInfo?: any, tenantFeatures?: int}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs Update" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # Properties of hub. — shape: {hubBillingInfo?: any, tenantFeatures?: int}
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a hub, or updates an existing hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_CreateOrUpdate
# --properties shape: {hubBillingInfo?: any, tenantFeatures?: int}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # Properties of hub. — shape: {hubBillingInfo?: any, tenantFeatures?: int}
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)" $qp)
  let body = {properties: $properties, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all the authorization policies in a specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies
# operationId: AuthorizationPolicies_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/authorizationPolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets an authorization policy in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}
# operationId: AuthorizationPolicies_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies Get" [
  resourceGroupName: string
  hubName: string
  authorizationPolicyName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/authorizationPolicies/($authorizationPolicyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an authorization policy or updates an existing authorization policy.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}
# operationId: AuthorizationPolicies_CreateOrUpdate
# --properties shape: {permissions: list, primaryKey?: string, secondaryKey?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  authorizationPolicyName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The authorization policy. — shape: {permissions: list, primaryKey?: string, secondaryKey?: string}
]: any -> record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/authorizationPolicies/($authorizationPolicyName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Regenerates the primary policy key of the specified authorization policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regeneratePrimaryKey
# operationId: AuthorizationPolicies_RegeneratePrimaryKey
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies-regenerate-primary-key RegeneratePrimaryKey" [
  resourceGroupName: string
  hubName: string
  authorizationPolicyName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/authorizationPolicies/($authorizationPolicyName)/regeneratePrimaryKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerates the secondary policy key of the specified authorization policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regenerateSecondaryKey
# operationId: AuthorizationPolicies_RegenerateSecondaryKey
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies-regenerate-secondary-key RegenerateSecondaryKey" [
  resourceGroupName: string
  hubName: string
  authorizationPolicyName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/authorizationPolicies/($authorizationPolicyName)/regenerateSecondaryKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all the connectors in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors
# operationId: Connectors_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a connector in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# operationId: Connectors_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors Delete" [
  resourceGroupName: string
  hubName: string
  connectorName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors/($connectorName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a connector in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# operationId: Connectors_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors Get" [
  resourceGroupName: string
  hubName: string
  connectorName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors/($connectorName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a connector or updates an existing connector in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# operationId: Connectors_CreateOrUpdate
# --properties shape: {connectorName?: string, connectorProperties: record, connectorType: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, isInternal?: bool}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  connectorName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # Properties of connector. — shape: {connectorName?: string, connectorProperties: record, connectorType: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, isInternal?: bool}
]: any -> record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors/($connectorName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all the connector mappings in the specified connector.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings
# operationId: ConnectorMappings_ListByConnector
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings ListByConnector" [
  resourceGroupName: string
  hubName: string
  connectorName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors/($connectorName)/mappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a connector mapping in the connector.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# operationId: ConnectorMappings_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings Delete" [
  resourceGroupName: string
  hubName: string
  connectorName: string
  mappingName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors/($connectorName)/mappings/($mappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a connector mapping in the connector.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# operationId: ConnectorMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings Get" [
  resourceGroupName: string
  hubName: string
  connectorName: string
  mappingName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors/($connectorName)/mappings/($mappingName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a connector mapping or updates an existing connector mapping in the connector.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# operationId: ConnectorMappings_CreateOrUpdate
# --properties shape: {connectorType?: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, mappingProperties: any}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  connectorName: string
  mappingName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The connector mapping definition. — shape: {connectorType?: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, mappingProperties: any}
]: any -> record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/connectors/($connectorName)/mappings/($mappingName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets data image upload URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getDataImageUploadUrl
# operationId: Images_GetUploadUrlForData
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-images-get-data-image-upload-url GetUploadUrlForData" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --entityType: string # Type of entity. Can be Profile or Interaction.
  --entityTypeName: string # Name of the entity type.
  --relativePath: string # Relative path of the image.
]: any -> record<contentUrl: string, imageExists: bool, relativePath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/images/getDataImageUploadUrl" $qp)
  let body = {entityType: $entityType, entityTypeName: $entityTypeName, relativePath: $relativePath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets entity type (profile or interaction) image upload URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getEntityTypeImageUploadUrl
# operationId: Images_GetUploadUrlForEntityType
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-images-get-entity-type-image-upload-url GetUploadUrlForEntityType" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --entityType: string # Type of entity. Can be Profile or Interaction.
  --entityTypeName: string # Name of the entity type.
  --relativePath: string # Relative path of the image.
]: any -> record<contentUrl: string, imageExists: bool, relativePath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/images/getEntityTypeImageUploadUrl" $qp)
  let body = {entityType: $entityType, entityTypeName: $entityTypeName, relativePath: $relativePath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all interactions in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions
# operationId: Interactions_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale-code: string # Locale of interaction to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/interactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified interaction.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}
# operationId: Interactions_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions Get" [
  resourceGroupName: string
  hubName: string
  interactionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale-code: string # Locale of interaction to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/interactions/($interactionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an interaction or updates an existing interaction within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}
# operationId: Interactions_CreateOrUpdate
# --properties shape: {defaultDataSource?: any, idPropertyNames?: list, isActivity?: bool, participantProfiles?: list, primaryParticipantProfilePropertyName?: string, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  interactionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The Interaction Type Definition — shape: {defaultDataSource?: any, idPropertyNames?: list, isActivity?: bool, participantProfiles?: list, primaryParticipantProfilePropertyName?: string, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
]: any -> record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/interactions/($interactionName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Suggests relationships to create relationship links.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}/suggestRelationshipLinks
# operationId: Interactions_SuggestRelationshipLinks
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions-suggest-relationship-links SuggestRelationshipLinks" [
  resourceGroupName: string
  hubName: string
  interactionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<interactionName: string, suggestedRelationships: table<existingRelationshipName: string, profileName: string, profilePropertyReferences: list, relatedProfileName: string, relatedProfilePropertyReferences: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/interactions/($interactionName)/suggestRelationshipLinks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all the KPIs in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi
# operationId: Kpi_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/kpi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a KPI in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# operationId: Kpi_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi Delete" [
  resourceGroupName: string
  hubName: string
  kpiName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/kpi/($kpiName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a KPI in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# operationId: Kpi_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi Get" [
  resourceGroupName: string
  hubName: string
  kpiName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/kpi/($kpiName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a KPI or updates an existing KPI in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# operationId: Kpi_CreateOrUpdate
# --properties shape: {aliases?: list, calculationWindow: "Lifetime"|"Hour"|"Day"|"Week"|"Month", calculationWindowFieldName?: string, description?: record, displayName?: record, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, expression: string, extracts?: list, filter?: string, function: "Sum"|"Avg"|"Min"|"Max"|"Last"|"Count"|"None"|"CountDistinct", groupBy?: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", thresHolds?: any, unit?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  kpiName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # Defines the KPI Threshold limits. — shape: {aliases?: list, calculationWindow: "Lifetime"|"Hour"|"Day"|"Week"|"Month", calculationWindowFieldName?: string, description?: record, displayName?: record, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, expression: string, extracts?: list, filter?: string, function: "Sum"|"Avg"|"Min"|"Max"|"Last"|"Count"|"None"|"CountDistinct", groupBy?: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", thresHolds?: any, unit?: string}
]: any -> record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/kpi/($kpiName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reprocesses the Kpi values of the specified KPI.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}/reprocess
# operationId: Kpi_Reprocess
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi-reprocess Reprocess" [
  resourceGroupName: string
  hubName: string
  kpiName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/kpi/($kpiName)/reprocess" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all the links in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links
# operationId: Links_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a link in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# operationId: Links_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links Delete" [
  resourceGroupName: string
  hubName: string
  linkName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/links/($linkName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a link in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# operationId: Links_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links Get" [
  resourceGroupName: string
  hubName: string
  linkName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/links/($linkName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a link or updates an existing link in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# operationId: Links_CreateOrUpdate
# --properties shape: {description?: record, displayName?: record, mappings?: list, operationType?: "Upsert"|"Delete", participantPropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", referenceOnly?: bool, sourceEntityType: "None"|"Profile"|"Interaction"|"Relationship", sourceEntityTypeName: string, targetEntityType: "None"|"Profile"|"Interaction"|"Relationship", targetEntityTypeName: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  linkName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The definition of Link. — shape: {description?: record, displayName?: record, mappings?: list, operationType?: "Upsert"|"Delete", participantPropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", referenceOnly?: bool, sourceEntityType: "None"|"Profile"|"Interaction"|"Relationship", sourceEntityTypeName: string, targetEntityType: "None"|"Profile"|"Interaction"|"Relationship", targetEntityTypeName: string}
]: any -> record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/links/($linkName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all the predictions in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions
# operationId: Predictions_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/predictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a Prediction in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# operationId: Predictions_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions Delete" [
  resourceGroupName: string
  hubName: string
  predictionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/predictions/($predictionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a Prediction in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# operationId: Predictions_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions Get" [
  resourceGroupName: string
  hubName: string
  predictionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/predictions/($predictionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Prediction or updates an existing Prediction in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# operationId: Predictions_CreateOrUpdate
# --properties shape: {autoAnalyze: bool, description?: record, displayName?: record, grades?: list, involvedInteractionTypes?: list, involvedKpiTypes?: list, involvedRelationships?: list, mappings: record, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName?: string, primaryProfileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", scopeExpression: string, scoreLabel: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  predictionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The prediction definition. — shape: {autoAnalyze: bool, description?: record, displayName?: record, grades?: list, involvedInteractionTypes?: list, involvedKpiTypes?: list, involvedRelationships?: list, mappings: record, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName?: string, primaryProfileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", scopeExpression: string, scoreLabel: string}
]: any -> record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/predictions/($predictionName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets model status of the prediction.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getModelStatus
# operationId: Predictions_GetModelStatus
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions-get-model-status GetModelStatus" [
  resourceGroupName: string
  hubName: string
  predictionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<message: string, modelVersion: string, predictionGuidId: string, predictionName: string, signalsUsed: int, status: string, tenantId: string, testSetCount: int, trainingAccuracy: int, trainingSetCount: int, validationSetCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/predictions/($predictionName)/getModelStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets training results.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getTrainingResults
# operationId: Predictions_GetTrainingResults
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions-get-training-results GetTrainingResults" [
  resourceGroupName: string
  hubName: string
  predictionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<canonicalProfiles: table<canonicalProfileId: int, properties: list>, predictionDistribution: record<distributions: list<record>, totalNegatives: int, totalPositives: int>, primaryProfileInstanceCount: int, scoreName: string, tenantId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/predictions/($predictionName)/getTrainingResults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates the model status of prediction.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/modelStatus
# operationId: Predictions_ModelStatus
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions-model-status ModelStatus" [
  resourceGroupName: string
  hubName: string
  predictionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  status: string@status-completer # Prediction model life cycle.  When prediction is in PendingModelConfirmation status, it is allowed to update the status to PendingFeaturing or Active through API.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/predictions/($predictionName)/modelStatus" $qp)
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all profile in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles
# operationId: Profiles_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a profile within a hub
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# operationId: Profiles_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles Delete" [
  resourceGroupName: string
  hubName: string
  profileName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/profiles/($profileName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# operationId: Profiles_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles Get" [
  resourceGroupName: string
  hubName: string
  profileName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/profiles/($profileName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a profile within a Hub, or updates an existing profile.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# operationId: Profiles_CreateOrUpdate
# --properties shape: {strongIds?: list, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  profileName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The profile type definition. — shape: {strongIds?: list, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
]: any -> record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/profiles/($profileName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the KPIs that enrich the profile Type identified by the supplied name. Enrichment happens through participants of the Interaction on an Interaction KPI and through Relationships for Profile KPIs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}/getEnrichingKpis
# operationId: Profiles_GetEnrichingKpis
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles-get-enriching-kpis GetEnrichingKpis" [
  resourceGroupName: string
  hubName: string
  profileName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> table<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/profiles/($profileName)/getEnrichingKpis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all relationship links in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks
# operationId: RelationshipLinks_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationshipLinks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a relationship link within a hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# operationId: RelationshipLinks_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links Delete" [
  resourceGroupName: string
  hubName: string
  relationshipLinkName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationshipLinks/($relationshipLinkName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified relationship Link.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# operationId: RelationshipLinks_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links Get" [
  resourceGroupName: string
  hubName: string
  relationshipLinkName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationshipLinks/($relationshipLinkName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a relationship link or updates an existing relationship link within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# operationId: RelationshipLinks_CreateOrUpdate
# --properties shape: {description?: record, displayName?: record, interactionType: string, mappings?: list, profilePropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfilePropertyReferences: list, relationshipName: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  relationshipLinkName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The definition of relationship link. — shape: {description?: record, displayName?: record, interactionType: string, mappings?: list, profilePropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfilePropertyReferences: list, relationshipName: string}
]: any -> record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationshipLinks/($relationshipLinkName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all relationships in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships
# operationId: Relationships_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a relationship within a hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# operationId: Relationships_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships Delete" [
  resourceGroupName: string
  hubName: string
  relationshipName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationships/($relationshipName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about the specified relationship.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# operationId: Relationships_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships Get" [
  resourceGroupName: string
  hubName: string
  relationshipName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationships/($relationshipName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a relationship or updates an existing relationship within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# operationId: Relationships_CreateOrUpdate
# --properties shape: {cardinality?: "OneToOne"|"OneToMany"|"ManyToMany", description?: record, displayName?: record, expiryDateTimeUtc?: string, fields?: list, lookupMappings?: list, profileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfileType: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  relationshipName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The definition of Relationship. — shape: {cardinality?: "OneToOne"|"OneToMany"|"ManyToMany", description?: record, displayName?: record, expiryDateTimeUtc?: string, fields?: list, lookupMappings?: list, profileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfileType: string}
]: any -> record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/relationships/($relationshipName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all the role assignments for the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments
# operationId: RoleAssignments_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/roleAssignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the role assignment in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# operationId: RoleAssignments_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments Delete" [
  resourceGroupName: string
  hubName: string
  assignmentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/roleAssignments/($assignmentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the role assignment in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# operationId: RoleAssignments_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments Get" [
  resourceGroupName: string
  hubName: string
  assignmentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/roleAssignments/($assignmentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a role assignment in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# operationId: RoleAssignments_CreateOrUpdate
# --properties shape: {conflationPolicies?: any, connectors?: any, description?: record, displayName?: record, interactions?: any, kpis?: any, links?: any, principals: list, profiles?: any, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relationshipLinks?: any, relationships?: any, role: "Admin"|"Reader"|"ManageAdmin"|"ManageReader"|"DataAdmin"|"DataReader", roleAssignments?: any, sasPolicies?: any, segments?: any, views?: any, widgetTypes?: any}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  assignmentName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The Role Assignment definition. — shape: {conflationPolicies?: any, connectors?: any, description?: record, displayName?: record, interactions?: any, kpis?: any, links?: any, principals: list, profiles?: any, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relationshipLinks?: any, relationships?: any, role: "Admin"|"Reader"|"ManageAdmin"|"ManageReader"|"DataAdmin"|"DataReader", roleAssignments?: any, sasPolicies?: any, segments?: any, views?: any, widgetTypes?: any}
]: any -> record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/roleAssignments/($assignmentName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all the roles for the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roles
# operationId: Roles_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-roles ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all available views for given user in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views
# operationId: Views_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --userId: string # The user ID. Use * to retrieve hub level views.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/views" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a view in the specified hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# operationId: Views_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views Delete" [
  resourceGroupName: string
  hubName: string
  viewName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --userId: string # The user ID. Use * to retrieve hub level view.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/views/($viewName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a view in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# operationId: Views_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views Get" [
  resourceGroupName: string
  hubName: string
  viewName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --userId: string # The user ID. Use * to retrieve hub level view.
]: nothing -> record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/views/($viewName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a view or updates an existing view in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# operationId: Views_CreateOrUpdate
# --properties shape: {definition: string, displayName?: record, userId?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views CreateOrUpdate" [
  resourceGroupName: string
  hubName: string
  viewName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # The view in Customer 360 web application. — shape: {definition: string, displayName?: record, userId?: string}
]: any -> record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/views/($viewName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all available widget types in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes
# operationId: WidgetTypes_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-widget-types ListByHub" [
  resourceGroupName: string
  hubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/widgetTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a widget type in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes/{widgetTypeName}
# operationId: WidgetTypes_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-widget-types Get" [
  resourceGroupName: string
  hubName: string
  widgetTypeName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<changed: string, created: string, definition: string, description: string, displayName: record, imageUrl: string, tenantId: string, widgetTypeName: string, widgetVersion: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.CustomerInsights/hubs/($hubName)/widgetTypes/($widgetTypeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
