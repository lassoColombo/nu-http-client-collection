# Auto-generated client for ServiceBusManagementClient v2017-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/servicebus/2017-04-01/swagger.json
# Auth: --token flag or $env.SERVICEBUSMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SERVICEBUSMANAGEMENTCLIENT_TOKEN | default "" }
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
def keyType-completer [] { ["PrimaryKey" "SecondaryKey"] }
def targetNamespaceType-completer [] { ["EventHub" "Messaging" "Mixed" "NotificationHub" "Relay"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-service-bus-operations List" } } | get name | first)
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

# Lists all of the available ServiceBus REST API operations.
#
# GET /providers/Microsoft.ServiceBus/operations
# operationId: Operations_List
export def "providers-microsoft-service-bus-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ServiceBus/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check the give namespace name availability.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.ServiceBus/CheckNameAvailability
# operationId: Namespaces_CheckNameAvailability
export def "subscriptions-providers-microsoft-service-bus-check-name-availability CheckNameAvailability" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  name: string # The Name to check the namespace name availability and The namespace name can contain only letters, numbers, and hyphens. The namespace must start with a letter, and it must end with a letter or number.
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.ServiceBus/CheckNameAvailability" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all the available namespaces within the subscription, irrespective of the resource groups.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.ServiceBus/namespaces
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639412.aspx
# operationId: Namespaces_List
export def "subscriptions-providers-microsoft-service-bus-namespaces List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.ServiceBus/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the available premium messaging regions for servicebus 
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.ServiceBus/premiumMessagingRegions
# operationId: PremiumMessagingRegions_List
export def "subscriptions-providers-microsoft-service-bus-premium-messaging-regions List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.ServiceBus/premiumMessagingRegions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the available Regions for a given sku
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.ServiceBus/sku/{sku}/regions
# operationId: Regions_ListBySku
export def "subscriptions-providers-microsoft-service-bus-sku-regions ListBySku" [
  subscriptionId: string
  sku: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.ServiceBus/sku/($sku)/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the available namespaces within a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639412.aspx
# operationId: Namespaces_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces ListByResourceGroup" [
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
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, sku: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing namespace. This operation also removes all associated resources under the namespace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639389.aspx
# operationId: Namespaces_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces Delete" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a description for the specified namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639379.aspx
# operationId: Namespaces_Get
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces Get" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<createdAt: string, metricId: string, provisioningState: string, serviceBusEndpoint: string, updatedAt: string>, sku: record<capacity: int, name: string, tier: string>, location: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a service namespace. Once created, this namespace's resource manifest is immutable. This operation is idempotent.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}
# operationId: Namespaces_Update
# --sku shape: {capacity?: int, name: "Basic"|"Standard"|"Premium", tier?: "Basic"|"Standard"|"Premium"}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces Update" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Properties of the namespace.
  --sku: record # SKU of the namespace. — shape: {capacity?: int, name: "Basic"|"Standard"|"Premium", tier?: "Basic"|"Standard"|"Premium"}
  --location: string # Resource location
  --tags: record # Resource tags
]: any -> record<properties: record<createdAt: string, metricId: string, provisioningState: string, serviceBusEndpoint: string, updatedAt: string>, sku: record<capacity: int, name: string, tier: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)" $qp)
  let body = {properties: $properties, sku: $sku, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates or updates a service namespace. Once created, this namespace's resource manifest is immutable. This operation is idempotent.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639408.aspx
# operationId: Namespaces_CreateOrUpdate
# --sku shape: {capacity?: int, name: "Basic"|"Standard"|"Premium", tier?: "Basic"|"Standard"|"Premium"}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces CreateOrUpdate" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Properties of the namespace.
  --sku: record # SKU of the namespace. — shape: {capacity?: int, name: "Basic"|"Standard"|"Premium", tier?: "Basic"|"Standard"|"Premium"}
  location: string # The Geo-location where the resource lives
  --tags: record # Resource tags
]: any -> record<properties: record<createdAt: string, metricId: string, provisioningState: string, serviceBusEndpoint: string, updatedAt: string>, sku: record<capacity: int, name: string, tier: string>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)" $qp)
  let body = {properties: $properties, sku: $sku, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the authorization rules for a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/AuthorizationRules
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639376.aspx
# operationId: Namespaces_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-authorization-rules ListAuthorizationRules" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/AuthorizationRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a namespace authorization rule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639417.aspx
# operationId: Namespaces_DeleteAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-authorization-rules DeleteAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an authorization rule for a namespace by rule name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639392.aspx
# operationId: Namespaces_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-authorization-rules GetAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<rights: list<string>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates an authorization rule for a namespace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639410.aspx
# operationId: Namespaces_CreateOrUpdateAuthorizationRule
# --properties shape: {rights: list}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-authorization-rules CreateOrUpdateAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # AuthorizationRule properties. — shape: {rights: list}
]: any -> record<properties: record<rights: list<string>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the primary and secondary connection strings for the namespace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}/listKeys
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639398.aspx
# operationId: Namespaces_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-authorization-rules-list-keys ListKeys" [
  resourceGroupName: string
  namespaceName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<aliasPrimaryConnectionString: string, aliasSecondaryConnectionString: string, keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerates the primary or secondary connection strings for the namespace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}/regenerateKeys
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt718977.aspx
# operationId: Namespaces_RegenerateKeys
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-authorization-rules-regenerate-keys RegenerateKeys" [
  resourceGroupName: string
  namespaceName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --key: string # Optional, if the key value provided, is reset for KeyType value or autogenerate Key value set for keyType
  keyType: string@keyType-completer # The access key to regenerate.
]: any -> record<aliasPrimaryConnectionString: string, aliasSecondaryConnectionString: string, keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)/regenerateKeys" $qp)
  let body = {key: $key, keyType: $keyType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all Alias(Disaster Recovery configurations)
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs
# operationId: DisasterRecoveryConfigs_List
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs List" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check the give namespace name availability.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/CheckNameAvailability
# operationId: DisasterRecoveryConfigs_CheckNameAvailability
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs-check-name-availability CheckNameAvailability" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  name: string # The Name to check the namespace name availability and The namespace name can contain only letters, numbers, and hyphens. The namespace must start with a letter, and it must end with a letter or number.
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/CheckNameAvailability" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an Alias(Disaster Recovery configuration)
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}
# operationId: DisasterRecoveryConfigs_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs Delete" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves Alias(Disaster Recovery configuration) for primary or secondary namespace
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}
# operationId: DisasterRecoveryConfigs_Get
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs Get" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<alternateName: string, partnerNamespace: string, pendingReplicationOperationsCount: int, provisioningState: string, role: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a new Alias(Disaster Recovery configuration)
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}
# operationId: DisasterRecoveryConfigs_CreateOrUpdate
# --properties shape: {alternateName?: string, partnerNamespace?: string}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs CreateOrUpdate" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Properties required to the Create Or Update Alias(Disaster Recovery configurations) — shape: {alternateName?: string, partnerNamespace?: string}
]: any -> record<properties: record<alternateName: string, partnerNamespace: string, pendingReplicationOperationsCount: int, provisioningState: string, role: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the authorization rules for a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}/AuthorizationRules
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639376.aspx
# operationId: DisasterRecoveryConfigs_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs-authorization-rules ListAuthorizationRules" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)/AuthorizationRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an authorization rule for a namespace by rule name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}/AuthorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639392.aspx
# operationId: DisasterRecoveryConfigs_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs-authorization-rules GetAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<rights: list<string>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)/AuthorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the primary and secondary connection strings for the namespace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}/AuthorizationRules/{authorizationRuleName}/listKeys
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639398.aspx
# operationId: DisasterRecoveryConfigs_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs-authorization-rules-list-keys ListKeys" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<aliasPrimaryConnectionString: string, aliasSecondaryConnectionString: string, keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)/AuthorizationRules/($authorizationRuleName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation disables the Disaster Recovery and stops replicating changes from primary to secondary namespaces
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}/breakPairing
# operationId: DisasterRecoveryConfigs_BreakPairing
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs-break-pairing BreakPairing" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)/breakPairing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invokes GEO DR failover and reconfigure the alias to point to the secondary namespace
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/disasterRecoveryConfigs/{alias}/failover
# operationId: DisasterRecoveryConfigs_FailOver
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-disaster-recovery-configs-failover FailOver" [
  resourceGroupName: string
  namespaceName: string
  alias: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/disasterRecoveryConfigs/($alias)/failover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the Event Hubs in a service bus Namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/eventhubs
# operationId: EventHubs_ListByNamespace
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-eventhubs ListByNamespace" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/eventhubs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation Migrate the given namespace to provided name type
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/migrate
# operationId: Namespaces_Migrate
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-migrate Migrate" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  targetNamespaceType: string@targetNamespaceType-completer # Type of namespaces
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/migrate" $qp)
  let body = {targetNamespaceType: $targetNamespaceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all migrationConfigurations
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/migrationConfigurations
# operationId: MigrationConfigs_List
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-migration-configurations List" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/migrationConfigurations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a MigrationConfiguration
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/migrationConfigurations/{configName}
# operationId: MigrationConfigs_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-migration-configurations Delete" [
  resourceGroupName: string
  namespaceName: string
  configName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/migrationConfigurations/($configName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves Migration Config
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/migrationConfigurations/{configName}
# operationId: MigrationConfigs_Get
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-migration-configurations Get" [
  resourceGroupName: string
  namespaceName: string
  configName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<migrationState: string, pendingReplicationOperationsCount: int, postMigrationName: string, provisioningState: string, targetNamespace: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/migrationConfigurations/($configName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates Migration configuration and starts migration of entities from Standard to Premium namespace
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/migrationConfigurations/{configName}
# operationId: MigrationConfigs_CreateAndStartMigration
# --properties shape: {postMigrationName: string, targetNamespace: string}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-migration-configurations CreateAndStartMigration" [
  resourceGroupName: string
  namespaceName: string
  configName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Properties required to the Create Migration Configuration — shape: {postMigrationName: string, targetNamespace: string}
]: any -> record<properties: record<migrationState: string, pendingReplicationOperationsCount: int, postMigrationName: string, provisioningState: string, targetNamespace: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/migrationConfigurations/($configName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This operation reverts Migration
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/migrationConfigurations/{configName}/revert
# operationId: MigrationConfigs_Revert
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-migration-configurations-revert Revert" [
  resourceGroupName: string
  namespaceName: string
  configName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/migrationConfigurations/($configName)/revert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This operation Completes Migration of entities by pointing the connection strings to Premium namespace and any entities created after the operation will be under Premium Namespace. CompleteMigration operation will fail when entity migration is in-progress.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/migrationConfigurations/{configName}/upgrade
# operationId: MigrationConfigs_CompleteMigration
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-migration-configurations-upgrade CompleteMigration" [
  resourceGroupName: string
  namespaceName: string
  configName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/migrationConfigurations/($configName)/upgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of NetworkRuleSet for a Namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/networkRuleSets
# operationId: Namespaces_ListNetworkRuleSets
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-network-rule-sets ListNetworkRuleSets" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/networkRuleSets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets NetworkRuleSet for a Namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/networkRuleSets/default
# operationId: Namespaces_GetNetworkRuleSet
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-network-rule-sets-default GetNetworkRuleSet" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<defaultAction: string, ipRules: list<record>, virtualNetworkRules: list<record>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/networkRuleSets/default" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update NetworkRuleSet for a Namespace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/networkRuleSets/default
# operationId: Namespaces_CreateOrUpdateNetworkRuleSet
# --properties shape: {defaultAction?: "Allow"|"Deny", ipRules?: list, virtualNetworkRules?: list}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-network-rule-sets-default CreateOrUpdateNetworkRuleSet" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # NetworkRuleSet properties — shape: {defaultAction?: "Allow"|"Deny", ipRules?: list, virtualNetworkRules?: list}
]: any -> record<properties: record<defaultAction: string, ipRules: list<record>, virtualNetworkRules: list<record>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/networkRuleSets/default" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the queues within a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639415.aspx
# operationId: Queues_ListByNamespace
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues ListByNamespace" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --skip: int # Skip is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skip parameter that specifies a starting point to use for subsequent calls.
  --top: int # May be used to limit the number of results to the most recent N usageDetails.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a queue from the specified namespace in a resource group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639411.aspx
# operationId: Queues_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues Delete" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a description for the specified queue.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639380.aspx
# operationId: Queues_Get
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues Get" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<accessedAt: string, autoDeleteOnIdle: string, countDetails: record<activeMessageCount: int, deadLetterMessageCount: int, scheduledMessageCount: int, transferDeadLetterMessageCount: int, transferMessageCount: int>, createdAt: string, deadLetteringOnMessageExpiration: bool, defaultMessageTimeToLive: string, duplicateDetectionHistoryTimeWindow: string, enableBatchedOperations: bool, enableExpress: bool, enablePartitioning: bool, forwardDeadLetteredMessagesTo: string, forwardTo: string, lockDuration: string, maxDeliveryCount: int, maxSizeInMegabytes: int, messageCount: int, requiresDuplicateDetection: bool, requiresSession: bool, sizeInBytes: int, status: string, updatedAt: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates or updates a Service Bus queue. This operation is idempotent.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639395.aspx
# operationId: Queues_CreateOrUpdate
# --properties shape: {autoDeleteOnIdle?: string, countDetails?: record, deadLetteringOnMessageExpiration?: bool, defaultMessageTimeToLive?: string, duplicateDetectionHistoryTimeWindow?: string, enableBatchedOperations?: bool, enableExpress?: bool, enablePartitioning?: bool, forwardDeadLetteredMessagesTo?: string, forwardTo?: string, lockDuration?: string, maxDeliveryCount?: int, maxSizeInMegabytes?: int, requiresDuplicateDetection?: bool, requiresSession?: bool, status?: "Active"|"Disabled"|"Restoring"|"SendDisabled"|"ReceiveDisabled"|"Creating"|"Deleting"|"Renaming"|"Unknown"}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues CreateOrUpdate" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # The Queue Properties definition. — shape: {autoDeleteOnIdle?: string, countDetails?: record, deadLetteringOnMessageExpiration?: bool, defaultMessageTimeToLive?: string, duplicateDetectionHistoryTimeWindow?: string, enableBatchedOperations?: bool, enableExpress?: bool, enablePartitioning?: bool, forwardDeadLetteredMessagesTo?: string, forwardTo?: string, lockDuration?: string, maxDeliveryCount?: int, maxSizeInMegabytes?: int, requiresDuplicateDetection?: bool, requiresSession?: bool, status?: "Active"|"Disabled"|"Restoring"|"SendDisabled"|"ReceiveDisabled"|"Creating"|"Deleting"|"Renaming"|"Unknown"}
]: any -> record<properties: record<accessedAt: string, autoDeleteOnIdle: string, countDetails: record<activeMessageCount: int, deadLetterMessageCount: int, scheduledMessageCount: int, transferDeadLetterMessageCount: int, transferMessageCount: int>, createdAt: string, deadLetteringOnMessageExpiration: bool, defaultMessageTimeToLive: string, duplicateDetectionHistoryTimeWindow: string, enableBatchedOperations: bool, enableExpress: bool, enablePartitioning: bool, forwardDeadLetteredMessagesTo: string, forwardTo: string, lockDuration: string, maxDeliveryCount: int, maxSizeInMegabytes: int, messageCount: int, requiresDuplicateDetection: bool, requiresSession: bool, sizeInBytes: int, status: string, updatedAt: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all authorization rules for a queue.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}/authorizationRules
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt705607.aspx
# operationId: Queues_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues-authorization-rules ListAuthorizationRules" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)/authorizationRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a queue authorization rule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}/authorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt705609.aspx
# operationId: Queues_DeleteAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues-authorization-rules DeleteAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)/authorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an authorization rule for a queue by rule name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}/authorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt705611.aspx
# operationId: Queues_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues-authorization-rules GetAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<rights: list<string>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)/authorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an authorization rule for a queue.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}/authorizationRules/{authorizationRuleName}
# operationId: Queues_CreateOrUpdateAuthorizationRule
# --properties shape: {rights: list}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues-authorization-rules CreateOrUpdateAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # AuthorizationRule properties. — shape: {rights: list}
]: any -> record<properties: record<rights: list<string>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)/authorizationRules/($authorizationRuleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Primary and secondary connection strings to the queue.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}/authorizationRules/{authorizationRuleName}/ListKeys
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt705608.aspx
# operationId: Queues_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues-authorization-rules-list-keys ListKeys" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<aliasPrimaryConnectionString: string, aliasSecondaryConnectionString: string, keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)/authorizationRules/($authorizationRuleName)/ListKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerates the primary or secondary connection strings to the queue.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/queues/{queueName}/authorizationRules/{authorizationRuleName}/regenerateKeys
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt705606.aspx
# operationId: Queues_RegenerateKeys
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-queues-authorization-rules-regenerate-keys RegenerateKeys" [
  resourceGroupName: string
  namespaceName: string
  queueName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --key: string # Optional, if the key value provided, is reset for KeyType value or autogenerate Key value set for keyType
  keyType: string@keyType-completer # The access key to regenerate.
]: any -> record<aliasPrimaryConnectionString: string, aliasSecondaryConnectionString: string, keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/queues/($queueName)/authorizationRules/($authorizationRuleName)/regenerateKeys" $qp)
  let body = {key: $key, keyType: $keyType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all the topics in a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639388.aspx
# operationId: Topics_ListByNamespace
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics ListByNamespace" [
  resourceGroupName: string
  namespaceName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --skip: int # Skip is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skip parameter that specifies a starting point to use for subsequent calls.
  --top: int # May be used to limit the number of results to the most recent N usageDetails.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a topic from the specified namespace and resource group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639404.aspx
# operationId: Topics_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics Delete" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a description for the specified topic.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639399.aspx
# operationId: Topics_Get
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics Get" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<accessedAt: string, autoDeleteOnIdle: string, countDetails: record<activeMessageCount: int, deadLetterMessageCount: int, scheduledMessageCount: int, transferDeadLetterMessageCount: int, transferMessageCount: int>, createdAt: string, defaultMessageTimeToLive: string, duplicateDetectionHistoryTimeWindow: string, enableBatchedOperations: bool, enableExpress: bool, enablePartitioning: bool, maxSizeInMegabytes: int, requiresDuplicateDetection: bool, sizeInBytes: int, status: string, subscriptionCount: int, supportOrdering: bool, updatedAt: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a topic in the specified namespace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639409.aspx
# operationId: Topics_CreateOrUpdate
# --properties shape: {autoDeleteOnIdle?: string, countDetails?: record, defaultMessageTimeToLive?: string, duplicateDetectionHistoryTimeWindow?: string, enableBatchedOperations?: bool, enableExpress?: bool, enablePartitioning?: bool, maxSizeInMegabytes?: int, requiresDuplicateDetection?: bool, status?: "Active"|"Disabled"|"Restoring"|"SendDisabled"|"ReceiveDisabled"|"Creating"|"Deleting"|"Renaming"|"Unknown", supportOrdering?: bool}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics CreateOrUpdate" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # The Topic Properties definition. — shape: {autoDeleteOnIdle?: string, countDetails?: record, defaultMessageTimeToLive?: string, duplicateDetectionHistoryTimeWindow?: string, enableBatchedOperations?: bool, enableExpress?: bool, enablePartitioning?: bool, maxSizeInMegabytes?: int, requiresDuplicateDetection?: bool, status?: "Active"|"Disabled"|"Restoring"|"SendDisabled"|"ReceiveDisabled"|"Creating"|"Deleting"|"Renaming"|"Unknown", supportOrdering?: bool}
]: any -> record<properties: record<accessedAt: string, autoDeleteOnIdle: string, countDetails: record<activeMessageCount: int, deadLetterMessageCount: int, scheduledMessageCount: int, transferDeadLetterMessageCount: int, transferMessageCount: int>, createdAt: string, defaultMessageTimeToLive: string, duplicateDetectionHistoryTimeWindow: string, enableBatchedOperations: bool, enableExpress: bool, enablePartitioning: bool, maxSizeInMegabytes: int, requiresDuplicateDetection: bool, sizeInBytes: int, status: string, subscriptionCount: int, supportOrdering: bool, updatedAt: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets authorization rules for a topic.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/authorizationRules
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt720681.aspx
# operationId: Topics_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-authorization-rules ListAuthorizationRules" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/authorizationRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a topic authorization rule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/authorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt720681.aspx
# operationId: Topics_DeleteAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-authorization-rules DeleteAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/authorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the specified authorization rule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/authorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt720676.aspx
# operationId: Topics_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-authorization-rules GetAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<rights: list<string>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/authorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an authorization rule for the specified topic.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/authorizationRules/{authorizationRuleName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt720678.aspx
# operationId: Topics_CreateOrUpdateAuthorizationRule
# --properties shape: {rights: list}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-authorization-rules CreateOrUpdateAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # AuthorizationRule properties. — shape: {rights: list}
]: any -> record<properties: record<rights: list<string>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/authorizationRules/($authorizationRuleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the primary and secondary connection strings for the topic.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/authorizationRules/{authorizationRuleName}/ListKeys
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt720677.aspx
# operationId: Topics_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-authorization-rules-list-keys ListKeys" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<aliasPrimaryConnectionString: string, aliasSecondaryConnectionString: string, keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/authorizationRules/($authorizationRuleName)/ListKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerates primary or secondary connection strings for the topic.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/authorizationRules/{authorizationRuleName}/regenerateKeys
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt720679.aspx
# operationId: Topics_RegenerateKeys
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-authorization-rules-regenerate-keys RegenerateKeys" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --key: string # Optional, if the key value provided, is reset for KeyType value or autogenerate Key value set for keyType
  keyType: string@keyType-completer # The access key to regenerate.
]: any -> record<aliasPrimaryConnectionString: string, aliasSecondaryConnectionString: string, keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/authorizationRules/($authorizationRuleName)/regenerateKeys" $qp)
  let body = {key: $key, keyType: $keyType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all the subscriptions under a specified topic.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639400.aspx
# operationId: Subscriptions_ListByTopic
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions ListByTopic" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --skip: int # Skip is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skip parameter that specifies a starting point to use for subsequent calls.
  --top: int # May be used to limit the number of results to the most recent N usageDetails.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a subscription from the specified topic.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions/{subscriptionName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639381.aspx
# operationId: Subscriptions_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions Delete" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions/($subscriptionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a subscription description for the specified topic.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions/{subscriptionName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639402.aspx
# operationId: Subscriptions_Get
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions Get" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<accessedAt: string, autoDeleteOnIdle: string, countDetails: record<activeMessageCount: int, deadLetterMessageCount: int, scheduledMessageCount: int, transferDeadLetterMessageCount: int, transferMessageCount: int>, createdAt: string, deadLetteringOnFilterEvaluationExceptions: bool, deadLetteringOnMessageExpiration: bool, defaultMessageTimeToLive: string, duplicateDetectionHistoryTimeWindow: string, enableBatchedOperations: bool, forwardDeadLetteredMessagesTo: string, forwardTo: string, lockDuration: string, maxDeliveryCount: int, messageCount: int, requiresSession: bool, status: string, updatedAt: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions/($subscriptionName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a topic subscription.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions/{subscriptionName}
# Docs: https://msdn.microsoft.com/en-us/library/azure/mt639385.aspx
# operationId: Subscriptions_CreateOrUpdate
# --properties shape: {autoDeleteOnIdle?: string, countDetails?: record, deadLetteringOnFilterEvaluationExceptions?: bool, deadLetteringOnMessageExpiration?: bool, defaultMessageTimeToLive?: string, duplicateDetectionHistoryTimeWindow?: string, enableBatchedOperations?: bool, forwardDeadLetteredMessagesTo?: string, forwardTo?: string, lockDuration?: string, maxDeliveryCount?: int, requiresSession?: bool, status?: "Active"|"Disabled"|"Restoring"|"SendDisabled"|"ReceiveDisabled"|"Creating"|"Deleting"|"Renaming"|"Unknown"}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions CreateOrUpdate" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Description of Subscription Resource. — shape: {autoDeleteOnIdle?: string, countDetails?: record, deadLetteringOnFilterEvaluationExceptions?: bool, deadLetteringOnMessageExpiration?: bool, defaultMessageTimeToLive?: string, duplicateDetectionHistoryTimeWindow?: string, enableBatchedOperations?: bool, forwardDeadLetteredMessagesTo?: string, forwardTo?: string, lockDuration?: string, maxDeliveryCount?: int, requiresSession?: bool, status?: "Active"|"Disabled"|"Restoring"|"SendDisabled"|"ReceiveDisabled"|"Creating"|"Deleting"|"Renaming"|"Unknown"}
]: any -> record<properties: record<accessedAt: string, autoDeleteOnIdle: string, countDetails: record<activeMessageCount: int, deadLetterMessageCount: int, scheduledMessageCount: int, transferDeadLetterMessageCount: int, transferMessageCount: int>, createdAt: string, deadLetteringOnFilterEvaluationExceptions: bool, deadLetteringOnMessageExpiration: bool, defaultMessageTimeToLive: string, duplicateDetectionHistoryTimeWindow: string, enableBatchedOperations: bool, forwardDeadLetteredMessagesTo: string, forwardTo: string, lockDuration: string, maxDeliveryCount: int, messageCount: int, requiresSession: bool, status: string, updatedAt: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions/($subscriptionName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all the rules within given topic-subscription
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions/{subscriptionName}/rules
# operationId: Rules_ListBySubscriptions
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions-rules ListBySubscriptions" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --skip: int # Skip is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skip parameter that specifies a starting point to use for subsequent calls.
  --top: int # May be used to limit the number of results to the most recent N usageDetails.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions/($subscriptionName)/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing rule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions/{subscriptionName}/rules/{ruleName}
# operationId: Rules_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions-rules Delete" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionName: string
  ruleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions/($subscriptionName)/rules/($ruleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the description for the specified rule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions/{subscriptionName}/rules/{ruleName}
# operationId: Rules_Get
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions-rules Get" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionName: string
  ruleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<properties: record<action: record<compatibilityLevel: int, requiresPreprocessing: bool, sqlExpression: string>, correlationFilter: record<contentType: string, correlationId: string, label: string, messageId: string, properties: record, replyTo: string, replyToSessionId: string, requiresPreprocessing: bool, sessionId: string, to: string>, filterType: string, sqlFilter: record<compatibilityLevel: int, requiresPreprocessing: bool, sqlExpression: string>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions/($subscriptionName)/rules/($ruleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new rule and updates an existing rule
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceBus/namespaces/{namespaceName}/topics/{topicName}/subscriptions/{subscriptionName}/rules/{ruleName}
# operationId: Rules_CreateOrUpdate
# --properties shape: {action?: record, correlationFilter?: record, filterType?: "SqlFilter"|"CorrelationFilter", sqlFilter?: record}
export def "subscriptions-resource-groups-providers-microsoft-service-bus-namespaces-topics-subscriptions-rules CreateOrUpdate" [
  resourceGroupName: string
  namespaceName: string
  topicName: string
  subscriptionName: string
  ruleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --properties: any # Description of Rule Resource. — shape: {action?: record, correlationFilter?: record, filterType?: "SqlFilter"|"CorrelationFilter", sqlFilter?: record}
]: any -> record<properties: record<action: record<compatibilityLevel: int, requiresPreprocessing: bool, sqlExpression: string>, correlationFilter: record<contentType: string, correlationId: string, label: string, messageId: string, properties: record, replyTo: string, replyToSessionId: string, requiresPreprocessing: bool, sessionId: string, to: string>, filterType: string, sqlFilter: record<compatibilityLevel: int, requiresPreprocessing: bool, sqlExpression: string>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.ServiceBus/namespaces/($namespaceName)/topics/($topicName)/subscriptions/($subscriptionName)/rules/($ruleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
