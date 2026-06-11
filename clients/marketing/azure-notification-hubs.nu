# Auto-generated client for NotificationHubsManagementClient v2017-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/notificationhubs/2017-04-01/swagger.json
# Auth: --token flag or $env.NOTIFICATIONHUBSMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOTIFICATIONHUBSMANAGEMENTCLIENT_TOKEN | default "" }
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-notification-hubs-operations List" } } | get name | first)
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

# Lists all of the available NotificationHubs REST API operations.
#
# GET /providers/Microsoft.NotificationHubs/operations
# operationId: Operations_List
export def "providers-microsoft-notification-hubs-operations List" [
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
  let full_url = (build-url $base "/providers/Microsoft.NotificationHubs/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checks the availability of the given service namespace across all Azure subscriptions. This is useful because the domain name is created based on the service namespace name.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.NotificationHubs/checkNamespaceAvailability
# operationId: Namespaces_CheckAvailability
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-providers-microsoft-notification-hubs-check-namespace-availability CheckAvailability" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --isAvailiable: string@bool-completer # True if the name is available and can be used to create new Namespace/NotificationHub. Otherwise false.
  --location: string # Resource location
  name: string # Resource name
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<isAvailiable: bool, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.NotificationHubs/checkNamespaceAvailability" $qp)
  let body = {isAvailiable: $isAvailiable, location: $location, name: $name, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all the available namespaces within the subscription irrespective of the resourceGroups.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.NotificationHubs/namespaces
# operationId: Namespaces_ListAll
export def "subscriptions-providers-microsoft-notification-hubs-namespaces ListAll" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.NotificationHubs/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the available namespaces within a resourceGroup.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces
# operationId: Namespaces_List
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces List" [
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an existing namespace. This operation also removes all associated notificationHubs under the namespace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# Docs: http://msdn.microsoft.com/en-us/library/windowsazure/jj856296.aspx
# operationId: Namespaces_Delete
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces Delete" [
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
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the description for the specified namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# operationId: Namespaces_Get
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces Get" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<createdAt: string, critical: bool, dataCenter: string, enabled: bool, metricId: string, name: string, namespaceType: string, provisioningState: string, region: string, scaleUnit: string, serviceBusEndpoint: string, status: string, subscriptionId: string, updatedAt: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patches the existing namespace
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# operationId: Namespaces_Patch
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces Patch" [
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
  --api-version: string # Client Api Version.
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<createdAt: string, critical: bool, dataCenter: string, enabled: bool, metricId: string, name: string, namespaceType: string, provisioningState: string, region: string, scaleUnit: string, serviceBusEndpoint: string, status: string, subscriptionId: string, updatedAt: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)" $qp)
  let body = {sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates/Updates a service namespace. Once created, this namespace's resource manifest is immutable. This operation is idempotent.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# Docs: http://msdn.microsoft.com/en-us/library/windowsazure/jj856303.aspx
# operationId: Namespaces_CreateOrUpdate
# --properties shape: {createdAt?: string, critical?: bool, dataCenter?: string, enabled?: bool, name?: string, namespaceType?: "Messaging"|"NotificationHub", provisioningState?: string, region?: string, scaleUnit?: string, serviceBusEndpoint?: string, status?: string, subscriptionId?: string, updatedAt?: string}
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces CreateOrUpdate" [
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
  --api-version: string # Client Api Version.
  --properties: any # Namespace properties. — shape: {createdAt?: string, critical?: bool, dataCenter?: string, enabled?: bool, name?: string, namespaceType?: "Messaging"|"NotificationHub", provisioningState?: string, region?: string, scaleUnit?: string, serviceBusEndpoint?: string, status?: string, subscriptionId?: string, updatedAt?: string}
  location: string # Resource location
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<createdAt: string, critical: bool, dataCenter: string, enabled: bool, metricId: string, name: string, namespaceType: string, provisioningState: string, region: string, scaleUnit: string, serviceBusEndpoint: string, status: string, subscriptionId: string, updatedAt: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)" $qp)
  let body = {properties: $properties, location: $location, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the authorization rules for a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules
# operationId: Namespaces_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules ListAuthorizationRules" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/AuthorizationRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a namespace authorization rule
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# operationId: Namespaces_DeleteAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules DeleteAuthorizationRule" [
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
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets an authorization rule for a namespace by name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# operationId: Namespaces_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules GetAuthorizationRule" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an authorization rule for a namespace
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# operationId: Namespaces_CreateOrUpdateAuthorizationRule
# --properties shape: {rights?: list}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules CreateOrUpdateAuthorizationRule" [
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
  --api-version: string # Client Api Version.
  properties: any # SharedAccessAuthorizationRule properties. — shape: {rights?: list}
]: any -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the Primary and Secondary ConnectionStrings to the namespace 
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}/listKeys
# operationId: Namespaces_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules-list-keys ListKeys" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerates the Primary/Secondary Keys to the Namespace Authorization Rule
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}/regenerateKeys
# operationId: Namespaces_RegenerateKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules-regenerate-keys RegenerateKeys" [
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
  --api-version: string # Client Api Version.
  --policyKey: string # Name of the key that has to be regenerated for the Namespace/Notification Hub Authorization Rule. The value can be Primary Key/Secondary Key.
]: any -> record<keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/AuthorizationRules/($authorizationRuleName)/regenerateKeys" $qp)
  let body = {policyKey: $policyKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Checks the availability of the given notificationHub in a namespace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/checkNotificationHubAvailability
# operationId: NotificationHubs_CheckNotificationHubAvailability
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-check-notification-hub-availability CheckNotificationHubAvailability" [
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
  --api-version: string # Client Api Version.
  --isAvailiable: string@bool-completer # True if the name is available and can be used to create new Namespace/NotificationHub. Otherwise false.
  --location: string # Resource location
  name: string # Resource name
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<isAvailiable: bool, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/checkNotificationHubAvailability" $qp)
  let body = {isAvailiable: $isAvailiable, location: $location, name: $name, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the notification hubs associated with a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs
# operationId: NotificationHubs_List
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs List" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a notification hub associated with a namespace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_Delete
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs Delete" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the notification hubs associated with a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_Get
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs Get" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, authorizationRules: list<record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, name: string, registrationTtl: string, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch a NotificationHub in a namespace.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_Patch
# --properties shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs Patch" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --properties: any # NotificationHub properties. — shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
  --location: string # Resource location
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, authorizationRules: list<record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, name: string, registrationTtl: string, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)" $qp)
  let body = {properties: $properties, location: $location, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates/Update a NotificationHub in a namespace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_CreateOrUpdate
# --properties shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs CreateOrUpdate" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  properties: any # NotificationHub properties. — shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
  --location: string # Resource location
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, authorizationRules: list<record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, name: string, registrationTtl: string, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)" $qp)
  let body = {properties: $properties, location: $location, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the authorization rules for a NotificationHub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules
# operationId: NotificationHubs_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules ListAuthorizationRules" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/AuthorizationRules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a notificationHub authorization rule
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}
# operationId: NotificationHubs_DeleteAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules DeleteAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  authorizationRuleName: string
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
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets an authorization rule for a NotificationHub by name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}
# operationId: NotificationHubs_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules GetAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates/Updates an authorization rule for a NotificationHub
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}
# operationId: NotificationHubs_CreateOrUpdateAuthorizationRule
# --properties shape: {rights?: list}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules CreateOrUpdateAuthorizationRule" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  properties: any # SharedAccessAuthorizationRule properties. — shape: {rights?: list}
]: any -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/AuthorizationRules/($authorizationRuleName)" $qp)
  let body = {properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the Primary and Secondary ConnectionStrings to the NotificationHub 
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}/listKeys
# operationId: NotificationHubs_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules-list-keys ListKeys" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/AuthorizationRules/($authorizationRuleName)/listKeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Regenerates the Primary/Secondary Keys to the NotificationHub Authorization Rule
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}/regenerateKeys
# operationId: NotificationHubs_RegenerateKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules-regenerate-keys RegenerateKeys" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  authorizationRuleName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --policyKey: string # Name of the key that has to be regenerated for the Namespace/Notification Hub Authorization Rule. The value can be Primary Key/Secondary Key.
]: any -> record<keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/AuthorizationRules/($authorizationRuleName)/regenerateKeys" $qp)
  let body = {policyKey: $policyKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# test send a push notification
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/debugsend
# operationId: NotificationHubs_DebugSend
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-debugsend DebugSend" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
  --body: record
]: any -> record<properties: record<failure: float, results: record, success: float>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/debugsend" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the PNS Credentials associated with a notification hub .
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/pnsCredentials
# operationId: NotificationHubs_GetPnsCredentials
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-pns-credentials GetPnsCredentials" [
  resourceGroupName: string
  namespaceName: string
  notificationHubName: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.NotificationHubs/namespaces/($namespaceName)/notificationHubs/($notificationHubName)/pnsCredentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
