# Auto-generated client for LogicManagementClient v2019-05-01
# Source: https://api.apis.guru/v2/specs/azure.com/logic/2019-05-01/swagger.json
# Auth: --token flag or $env.LOGICMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOGICMANAGEMENTCLIENT_TOKEN | default "" }
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
def key-type-completer [] { ["NotSpecified" "Primary" "Secondary"] }
def track-events-options-completer [] { ["DisableSourceInfoEnrich" "None"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-logic-operations list" } } | get name | first)
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

# Lists all of the available Logic REST API operations.
#
# GET /providers/Microsoft.Logic/operations
# operationId: Operations_List
export def "providers-microsoft-logic-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Logic/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of integration accounts by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationAccounts
# operationId: IntegrationAccounts_ListBySubscription
export def "subscriptions-providers-microsoft-logic-integration-accounts list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Logic/integrationAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of integration service environments by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/integrationServiceEnvironments
# operationId: IntegrationServiceEnvironments_ListBySubscription
export def "subscriptions-providers-microsoft-logic-integration-service-environments list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Logic/integrationServiceEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of workflows by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Logic/workflows
# operationId: Workflows_ListBySubscription
export def "subscriptions-providers-microsoft-logic-workflows list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: State, Trigger, and ReferencedResourceId.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Logic/workflows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of integration accounts by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts
# operationId: IntegrationAccounts_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts list" [
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
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record>, state: string>, sku: record<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an integration account.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_Update
# --properties shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
# --sku shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The integration account properties. — shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration account sku. — shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record>, state: string>, sku: record<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates or updates an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}
# operationId: IntegrationAccounts_CreateOrUpdate
# --properties shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
# --sku shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The integration account properties. — shape: {integrationServiceEnvironment?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration account sku. — shape: {name: "NotSpecified"|"Free"|"Basic"|"Standard"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record>, state: string>, sku: record<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of integration account agreements.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements
# operationId: IntegrationAccountAgreements_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-agreements list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: AgreementType.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration account agreement.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# operationId: IntegrationAccountAgreements_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-agreements delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration account agreement.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# operationId: IntegrationAccountAgreements_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-agreements get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an integration account agreement.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}
# operationId: IntegrationAccountAgreements_CreateOrUpdate
# --properties shape: {agreementType: "NotSpecified"|"AS2"|"X12"|"Edifact", content: record, guestIdentity: record, guestPartner: string, hostIdentity: record, hostPartner: string, metadata?: record}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-agreements create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The integration account agreement properties. — shape: {agreementType: "NotSpecified"|"AS2"|"X12"|"Edifact", content: record, guestIdentity: record, guestPartner: string, hostIdentity: record, hostPartner: string, metadata?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<agreementType: string, changedTime: string, content: record<aS2: record, edifact: record, x12: record>, createdTime: string, guestIdentity: record<qualifier: string, value: string>, guestPartner: string, hostIdentity: record<qualifier: string, value: string>, hostPartner: string, metadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/agreements/{agreementName}/listContentCallbackUrl
# operationId: IntegrationAccountAgreements_ListContentCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-agreements-list-content-callback-url list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  agreement_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), agreement_name: (encode-path-segment $agreement_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/agreements/{agreement_name}/listContentCallbackUrl") $qp)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the assemblies for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies
# operationId: IntegrationAccountAssemblies_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-assemblies list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an assembly for an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# operationId: IntegrationAccountAssemblies_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-assemblies delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an assembly for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# operationId: IntegrationAccountAssemblies_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-assemblies get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an assembly for an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}
# operationId: IntegrationAccountAssemblies_CreateOrUpdate
# --properties shape: {assemblyCulture?: string, assemblyName: string, assemblyPublicKeyToken?: string, assemblyVersion?: string, content?: any, contentLink?: record, contentType?: string}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-assemblies create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The assembly properties definition. — shape: {assemblyCulture?: string, assemblyName: string, assemblyPublicKeyToken?: string, assemblyVersion?: string, content?: any, contentLink?: record, contentType?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<assemblyCulture: string, assemblyName: string, assemblyPublicKeyToken: string, assemblyVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the content callback url for an integration account assembly.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/assemblies/{assemblyArtifactName}/listContentCallbackUrl
# operationId: IntegrationAccountAssemblies_ListContentCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-assemblies-list-content-callback-url list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  assembly_artifact_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), assembly_artifact_name: (encode-path-segment $assembly_artifact_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/assemblies/{assembly_artifact_name}/listContentCallbackUrl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the batch configurations for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations
# operationId: IntegrationAccountBatchConfigurations_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-batch-configurations list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a batch configuration for an integration account.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# operationId: IntegrationAccountBatchConfigurations_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-batch-configurations delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), batch_configuration_name: (encode-path-segment $batch_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations/{batch_configuration_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a batch configuration for an integration account.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# operationId: IntegrationAccountBatchConfigurations_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-batch-configurations get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), batch_configuration_name: (encode-path-segment $batch_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations/{batch_configuration_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a batch configuration for an integration account.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/batchConfigurations/{batchConfigurationName}
# operationId: IntegrationAccountBatchConfigurations_CreateOrUpdate
# --properties shape: {batchGroupName: string, changedTime?: string, createdTime?: string, releaseCriteria: record, metadata?: any}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-batch-configurations create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  batch_configuration_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The batch configuration properties definition. — shape: {batchGroupName: string, changedTime?: string, createdTime?: string, releaseCriteria: record, metadata?: any}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<batchGroupName: string, changedTime: string, createdTime: string, releaseCriteria: record<batchSize: int, messageCount: int, recurrence: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), batch_configuration_name: (encode-path-segment $batch_configuration_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/batchConfigurations/{batch_configuration_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of integration account certificates.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates
# operationId: IntegrationAccountCertificates_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-certificates list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration account certificate.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# operationId: IntegrationAccountCertificates_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-certificates delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates/{certificate_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration account certificate.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# operationId: IntegrationAccountCertificates_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-certificates get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates/{certificate_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an integration account certificate.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/certificates/{certificateName}
# operationId: IntegrationAccountCertificates_CreateOrUpdate
# --properties shape: {key?: record, metadata?: record, publicCertificate?: string}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-certificates create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  certificate_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The integration account certificate properties. — shape: {key?: record, metadata?: record, publicCertificate?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<changedTime: string, createdTime: string, key: record<keyName: string, keyVault: record, keyVersion: string>, metadata: record, publicCertificate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), certificate_name: (encode-path-segment $certificate_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/certificates/{certificate_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the integration account callback URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listCallbackUrl
# operationId: IntegrationAccounts_ListCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-list-callback-url list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> record<value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/listCallbackUrl") $qp)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the integration account's Key Vault keys.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/listKeyVaultKeys
# operationId: IntegrationAccounts_ListKeyVaultKeys
# --keyVault shape: {id?: string}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-list-key-vault-keys list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  key_vault: record # The key vault reference. — shape: {id?: string}
  --skip-token: string # The skip token.
]: any -> record<skipToken: string, value: table<attributes: record, kid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/listKeyVaultKeys") $qp)
  let req_body = {"keyVault": $key_vault, "skipToken": $skip_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Logs the integration account's tracking events.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/logTrackingEvents
# operationId: IntegrationAccounts_LogTrackingEvents
# --events item shape: {error?: record, eventLevel: "LogAlways"|"Critical"|"Error"|"Warning"|"Informational"|"Verbose", eventTime: string, ... (1 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-log-tracking-events create" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  events: list # The events. — item shape: {error?: record, eventLevel: "LogAlways"|"Critical"|"Error"|"Warning"|"Informational"|"Verbose", eventTime: string, ... (1 more fields)}
  source_type: string # The source type.
  --track-events-options: string@track-events-options-completer # The track events operation options.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/logTrackingEvents") $qp)
  let req_body = {"events": $events, "sourceType": $source_type, "trackEventsOptions": $track_events_options} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of integration account maps.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps
# operationId: IntegrationAccountMaps_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-maps list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: MapType.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration account map.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# operationId: IntegrationAccountMaps_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-maps delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration account map.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# operationId: IntegrationAccountMaps_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-maps get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an integration account map.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}
# operationId: IntegrationAccountMaps_CreateOrUpdate
# --properties shape: {content?: string, contentLink?: record, contentType?: string, mapType: "NotSpecified"|"Xslt"|"Xslt20"|"Xslt30"|"Liquid", metadata?: record, parametersSchema?: record}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-maps create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The integration account map. — shape: {content?: string, contentLink?: record, contentType?: string, mapType: "NotSpecified"|"Xslt"|"Xslt20"|"Xslt30"|"Liquid", metadata?: record, parametersSchema?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, mapType: string, metadata: record, parametersSchema: record<ref: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/maps/{mapName}/listContentCallbackUrl
# operationId: IntegrationAccountMaps_ListContentCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-maps-list-content-callback-url list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  map_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), map_name: (encode-path-segment $map_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/maps/{map_name}/listContentCallbackUrl") $qp)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of integration account partners.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners
# operationId: IntegrationAccountPartners_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-partners list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: PartnerType.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration account partner.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# operationId: IntegrationAccountPartners_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-partners delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration account partner.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# operationId: IntegrationAccountPartners_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-partners get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an integration account partner.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}
# operationId: IntegrationAccountPartners_CreateOrUpdate
# --properties shape: {content: record, metadata?: record, partnerType: "NotSpecified"|"B2B"}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-partners create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The integration account partner properties. — shape: {content: record, metadata?: record, partnerType: "NotSpecified"|"B2B"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<changedTime: string, content: record<b2b: record>, createdTime: string, metadata: record, partnerType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/partners/{partnerName}/listContentCallbackUrl
# operationId: IntegrationAccountPartners_ListContentCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-partners-list-content-callback-url list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  partner_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), partner_name: (encode-path-segment $partner_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/partners/{partner_name}/listContentCallbackUrl") $qp)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Regenerates the integration account access key.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/regenerateAccessKey
# operationId: IntegrationAccounts_RegenerateAccessKey
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-regenerate-access-key create" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
]: any -> record<properties: record<integrationServiceEnvironment: record<properties: record, sku: record>, state: string>, sku: record<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/regenerateAccessKey") $qp)
  let req_body = {"keyType": $key_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of integration account schemas.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas
# operationId: IntegrationAccountSchemas_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-schemas list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: SchemaType.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration account schema.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# operationId: IntegrationAccountSchemas_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-schemas delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration account schema.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# operationId: IntegrationAccountSchemas_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-schemas get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an integration account schema.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}
# operationId: IntegrationAccountSchemas_CreateOrUpdate
# --properties shape: {content?: string, contentLink?: record, contentType?: string, documentName?: string, fileName?: string, metadata?: record, schemaType: "NotSpecified"|"Xml", targetNamespace?: string}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-schemas create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The integration account schema properties. — shape: {content?: string, contentLink?: record, contentType?: string, documentName?: string, fileName?: string, metadata?: record, schemaType: "NotSpecified"|"Xml", targetNamespace?: string}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<changedTime: string, content: string, contentLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, contentType: string, createdTime: string, documentName: string, fileName: string, metadata: record, schemaType: string, targetNamespace: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the content callback url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/schemas/{schemaName}/listContentCallbackUrl
# operationId: IntegrationAccountSchemas_ListContentCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-schemas-list-content-callback-url list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/schemas/{schema_name}/listContentCallbackUrl") $qp)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of integration account sessions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions
# operationId: IntegrationAccountSessions_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-sessions list" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: ChangedTime.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration account session.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# operationId: IntegrationAccountSessions_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-sessions delete" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), session_name: (encode-path-segment $session_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions/{session_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration account session.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# operationId: IntegrationAccountSessions_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-sessions get" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<changedTime: string, content: record, createdTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), session_name: (encode-path-segment $session_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions/{session_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an integration account session.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/integrationAccounts/{integrationAccountName}/sessions/{sessionName}
# operationId: IntegrationAccountSessions_CreateOrUpdate
# --properties shape: {content?: record}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-accounts-sessions create-or-update" [
  subscription_id: string
  resource_group_name: string
  integration_account_name: string
  session_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  properties: record # The integration account session properties. — shape: {content?: record}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<changedTime: string, content: record, createdTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), integration_account_name: (encode-path-segment $integration_account_name), session_name: (encode-path-segment $session_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/integrationAccounts/{integration_account_name}/sessions/{session_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Validates the workflow definition.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/locations/{location}/workflows/{workflowName}/validate
# operationId: Workflows_ValidateByLocation
export def "subscriptions-resource-groups-providers-microsoft-logic-locations-workflows-validate validate" [
  subscription_id: string
  resource_group_name: string
  location: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), location: (encode-path-segment $location), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/locations/{location}/workflows/{workflow_name}/validate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of workflows by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows
# operationId: Workflows_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows list" [
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
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: State, Trigger, and ReferencedResourceId.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a workflow.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows delete" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a workflow.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_Update
# --properties shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows update" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates or updates a workflow.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}
# operationId: Workflows_CreateOrUpdate
# --properties shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows create-or-update" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, endpointsConfiguration: record<connector: record, workflow: record>, integrationAccount: record<id: string, name: string, type: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, parameters: record, provisioningState: string, sku: record<name: string, plan: record>, state: string, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disables a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/disable
# operationId: Workflows_Disable
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-disable disable" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/disable") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enables a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/enable
# operationId: Workflows_Enable
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-enable enable" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/enable") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates the upgraded definition for a workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/generateUpgradedDefinition
# operationId: Workflows_GenerateUpgradedDefinition
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-generate-upgraded-definition generate" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --target-schema-version: string # The target schema version.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/generateUpgradedDefinition") $qp)
  let req_body = {"targetSchemaVersion": $target_schema_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the workflow callback Url.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listCallbackUrl
# operationId: Workflows_ListCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-list-callback-url list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/listCallbackUrl") $qp)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets an OpenAPI definition for the workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/listSwagger
# operationId: Workflows_ListSwagger
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-list-swagger list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/listSwagger") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Moves an existing workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/move
# operationId: Workflows_Move
# --properties shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-move move" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/move") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Regenerates the callback URL access key for request triggers.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/regenerateAccessKey
# operationId: Workflows_RegenerateAccessKey
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-regenerate-access-key create" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/regenerateAccessKey") $qp)
  let req_body = {"keyType": $key_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of workflow runs.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs
# operationId: WorkflowRuns_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status, StartTime, and ClientTrackingId.
]: nothing -> record<nextLink: string, value: table<name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}
# operationId: WorkflowRuns_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of workflow run actions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions
# operationId: WorkflowRunActions_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status.
]: nothing -> record<nextLink: string, value: table<name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow run action.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}
# operationId: WorkflowRunActions_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, retryHistory: list<record>, startTime: string, status: string, trackedProperties: record, trackingId: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists a workflow run expression trace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/listExpressionTraces
# operationId: WorkflowRunActions_ListExpressionTraces
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-list-expression-traces list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<inputs: table<path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/listExpressionTraces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all of a workflow run action repetitions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions
# operationId: WorkflowRunActionRepetitions_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-repetitions list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a workflow run action repetition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}
# operationId: WorkflowRunActionRepetitions_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-repetitions get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<repetitionIndexes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists a workflow run expression trace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/listExpressionTraces
# operationId: WorkflowRunActionRepetitions_ListExpressionTraces
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-repetitions-list-expression-traces list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<inputs: table<path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}/listExpressionTraces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a workflow run repetition request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories
# operationId: WorkflowRunActionRepetitionsRequestHistories_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-repetitions-request-histories list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}/requestHistories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow run repetition request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/repetitions/{repetitionName}/requestHistories/{requestHistoryName}
# operationId: WorkflowRunActionRepetitionsRequestHistories_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-repetitions-request-histories get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  request_history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name), request_history_name: (encode-path-segment $request_history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/repetitions/{repetition_name}/requestHistories/{request_history_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a workflow run request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories
# operationId: WorkflowRunActionRequestHistories_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-request-histories list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/requestHistories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow run request history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/requestHistories/{requestHistoryName}
# operationId: WorkflowRunActionRequestHistories_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-request-histories get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  request_history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<endTime: string, request: record<headers: record, method: string, uri: string>, response: record<bodyLink: record, headers: record, statusCode: int>, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), request_history_name: (encode-path-segment $request_history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/requestHistories/{request_history_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the workflow run action scoped repetitions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions
# operationId: WorkflowRunActionScopeRepetitions_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-scope-repetitions list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/scopeRepetitions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a workflow run action scoped repetition.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/actions/{actionName}/scopeRepetitions/{repetitionName}
# operationId: WorkflowRunActionScopeRepetitions_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-actions-scope-repetitions get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  action_name: string
  repetition_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<repetitionIndexes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), action_name: (encode-path-segment $action_name), repetition_name: (encode-path-segment $repetition_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/actions/{action_name}/scopeRepetitions/{repetition_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancels a workflow run.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/cancel
# operationId: WorkflowRuns_Cancel
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-cancel cancel" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an operation for a run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/runs/{runName}/operations/{operationId}
# operationId: WorkflowRunOperations_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-runs-operations get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  run_name: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, correlationId: string, endTime: string, error: record, outputs: record, response: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, startTime: string, status: string, trigger: record<code: string, correlation: record, endTime: string, error: record, inputs: record, inputsLink: record, name: string, outputs: record, outputsLink: record, scheduledTime: string, startTime: string, status: string, trackedProperties: record, trackingId: string>, waitEndTime: string, workflow: record<id: string, name: string, type: string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), run_name: (encode-path-segment $run_name), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/runs/{run_name}/operations/{operation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of workflow triggers.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers
# operationId: WorkflowTriggers_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation.
]: nothing -> record<nextLink: string, value: table<name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow trigger.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}
# operationId: WorkflowTriggers_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<changedTime: string, createdTime: string, lastExecutionTime: string, nextExecutionTime: string, provisioningState: string, recurrence: record<endTime: string, frequency: string, interval: int, schedule: record, startTime: string, timeZone: string>, state: string, status: string, workflow: record<id: string, name: string, type: string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of workflow trigger histories.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories
# operationId: WorkflowTriggerHistories_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-histories list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
  --filter: string # The filter to apply on the operation. Options for filters include: Status, StartTime, and ClientTrackingId.
]: nothing -> record<nextLink: string, value: table<name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/histories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow trigger history.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}
# operationId: WorkflowTriggerHistories_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-histories get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<name: string, properties: record<code: string, correlation: record<clientTrackingId: string>, endTime: string, error: record, fired: bool, inputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, outputsLink: record<contentHash: record, contentSize: int, contentVersion: string, metadata: record, uri: string>, run: record<id: string, name: string, type: string>, startTime: string, status: string, trackingId: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name), history_name: (encode-path-segment $history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/histories/{history_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resubmits a workflow run based on the trigger history.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/histories/{historyName}/resubmit
# operationId: WorkflowTriggerHistories_Resubmit
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-histories-resubmit trigger" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  history_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name), history_name: (encode-path-segment $history_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/histories/{history_name}/resubmit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the callback URL for a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/listCallbackUrl
# operationId: WorkflowTriggers_ListCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-list-callback-url list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/listCallbackUrl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resets a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/reset
# operationId: WorkflowTriggers_Reset
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-reset reset" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/reset") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/run
# operationId: WorkflowTriggers_Run
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-run create" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/run") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the trigger schema as JSON.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/schemas/json
# operationId: WorkflowTriggers_GetSchemaJson
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-schemas-json get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<content: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/schemas/json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the state of a workflow trigger.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/triggers/{triggerName}/setState
# operationId: WorkflowTriggers_SetState
# --source shape: {properties?: record}
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-triggers-set-state update" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --body-source: record # The workflow trigger. — shape: {properties?: record}
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/triggers/{trigger_name}/setState") $qp)
  let req_body = {"source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Validates the workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/validate
# operationId: Workflows_ValidateByResourceGroup
# --properties shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-validate validate" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The workflow properties. — shape: {definition?: record, endpointsConfiguration?: record, integrationAccount?: record, integrationServiceEnvironment?: record, parameters?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", sku?: record, state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<error: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/validate") $qp)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of workflow versions.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions
# operationId: WorkflowVersions_List
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-versions list" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a workflow version.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}
# operationId: WorkflowVersions_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-versions get" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<accessEndpoint: string, changedTime: string, createdTime: string, definition: record, integrationAccount: record<id: string, name: string, type: string>, parameters: record, sku: record<name: string, plan: record>, state: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), version_id: (encode-path-segment $version_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/versions/{version_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the callback url for a trigger of a workflow version.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Logic/workflows/{workflowName}/versions/{versionId}/triggers/{triggerName}/listCallbackUrl
# operationId: WorkflowVersionTriggers_ListCallbackUrl
export def "subscriptions-resource-groups-providers-microsoft-logic-workflows-versions-triggers-list-callback-url version" [
  subscription_id: string
  resource_group_name: string
  workflow_name: string
  version_id: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --key-type: string@key-type-completer # The key type.
  --not-after: string # The expiry time. (format: date-time)
]: any -> record<basePath: string, method: string, queries: record<api_version: string, se: string, sig: string, sp: string, sv: string>, relativePath: string, relativePathParameters: list<string>, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workflow_name: (encode-path-segment $workflow_name), version_id: (encode-path-segment $version_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Logic/workflows/{workflow_name}/versions/{version_id}/triggers/{trigger_name}/listCallbackUrl") $qp)
  let req_body = {"keyType": $key_type, "notAfter": $not_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of integration service environments by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments
# operationId: IntegrationServiceEnvironments_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments list" [
  subscription_id: string
  resource_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --top: int # The number of items to be included in the result. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an integration service environment.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments delete" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an integration service environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an integration service environment.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_Update
# --properties shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
# --sku shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments update" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The integration service environment properties. — shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration service environment sku. — shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates or updates an integration service environment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}
# operationId: IntegrationServiceEnvironments_CreateOrUpdate
# --properties shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
# --sku shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments create-or-update" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
  --properties: record # The integration service environment properties. — shape: {endpointsConfiguration?: record, integrationServiceEnvironmentId?: string, networkConfiguration?: record, provisioningState?: "NotSpecified"|"Accepted"|"Running"|"Ready"|"Creating"|"Created"|"Deleting"|"Deleted"|"Canceled"|"Failed"|"Succeeded"|"Moving"|"Updating"|"Registering"|"Registered"|"Unregistering"|"Unregistered"|"Completed", state?: "NotSpecified"|"Completed"|"Enabled"|"Disabled"|"Deleted"|"Suspended"}
  --sku: record # The integration service environment sku. — shape: {capacity?: int, name?: "NotSpecified"|"Premium"|"Developer"}
  --location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<properties: record<endpointsConfiguration: record<connector: record, workflow: record>, integrationServiceEnvironmentId: string, networkConfiguration: record<accessEndpoint: record, subnets: list, virtualNetworkAddressSpace: string>, provisioningState: string, state: string>, sku: record<capacity: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}") $qp)
  let req_body = {"properties": $properties, "sku": $sku, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the integration service environment network health.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/health/network
# operationId: IntegrationServiceEnvironmentNetworkHealth_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-health-network get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/health/network") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the integration service environment managed Apis.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis
# operationId: IntegrationServiceEnvironmentManagedApis_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-managed-apis list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the integration service environment managed Api.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# operationId: IntegrationServiceEnvironmentManagedApis_Delete
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-managed-apis delete" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the integration service environment managed Api.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# operationId: IntegrationServiceEnvironmentManagedApis_Get
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-managed-apis get" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts the integration service environment managed Api.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}
# operationId: IntegrationServiceEnvironmentManagedApis_Put
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-managed-apis update" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<properties: record<apiDefinitionUrl: string, apiDefinitions: record<modifiedSwaggerUrl: string, originalSwaggerUrl: string>, backendService: record<serviceUrl: string>, capabilities: list<string>, category: string, connectionParameters: record, generalInformation: record<description: string, displayName: string, iconUrl: string, releaseTag: string, termsOfUseUrl: string, tier: string>, integrationServiceEnvironment: record<id: string, name: string, type: string>, metadata: record<ApiType: string, brandColor: string, connectionType: string, deploymentParameters: record, hideKey: string, provisioningState: string, source: string, tags: record, wsdlImportMethod: string, wsdlService: record>, name: string, policies: record<content: string, contentLink: string>, provisioningState: string, runtimeUrls: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the managed Api operations.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/managedApis/{apiName}/apiOperations
# operationId: IntegrationServiceEnvironmentManagedApiOperations_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-managed-apis-api-operations list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  api_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name), api_name: (encode-path-segment $api_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/managedApis/{api_name}/apiOperations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restarts an integration service environment.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/restart
# operationId: IntegrationServiceEnvironments_Restart
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-restart restart" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/restart") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of integration service environment Skus.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Logic/integrationServiceEnvironments/{integrationServiceEnvironmentName}/skus
# operationId: IntegrationServiceEnvironmentSkus_List
export def "subscriptions-resource-groups-providers-microsoft-logic-integration-service-environments-skus list" [
  subscription_id: string
  resource_group: string
  integration_service_environment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version.
]: nothing -> record<nextLink: string, value: table<capacity: record, resourceType: string, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), integration_service_environment_name: (encode-path-segment $integration_service_environment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Logic/integrationServiceEnvironments/{integration_service_environment_name}/skus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
