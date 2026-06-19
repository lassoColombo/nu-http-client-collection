# Auto-generated client for NotificationHubsManagementClient v2017-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/notificationhubs/2017-04-01/swagger.json
# Auth: --token flag or $env.NOTIFICATIONHUBSMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOTIFICATIONHUBSMANAGEMENTCLIENT_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-notification-hubs-operations list" } } | get name | first)
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
export def "providers-microsoft-notification-hubs-operations list" [
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
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.NotificationHubs/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Checks the availability of the given service namespace across all Azure subscriptions. This is useful because the domain name is created based on the service namespace name.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.NotificationHubs/checkNamespaceAvailability
# operationId: Namespaces_CheckAvailability
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-providers-microsoft-notification-hubs-check-namespace-availability check" [
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
  --api-version: string # Client Api Version.
  --is-availiable: oneof<nothing, bool> # True if the name is available and can be used to create new Namespace/NotificationHub. Otherwise false.
  --location: string # Resource location
  name: string # Resource name
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<isAvailiable: bool, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.NotificationHubs/checkNamespaceAvailability") $qp)
  let req_body = {"isAvailiable": $is_availiable, "location": $location, "name": $name, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all the available namespaces within the subscription irrespective of the resourceGroups.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.NotificationHubs/namespaces
# operationId: Namespaces_ListAll
export def "subscriptions-providers-microsoft-notification-hubs-namespaces list" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.NotificationHubs/namespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the available namespaces within a resourceGroup.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces
# operationId: Namespaces_List
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces list" [
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
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes an existing namespace. This operation also removes all associated notificationHubs under the namespace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# Docs: http://msdn.microsoft.com/en-us/library/windowsazure/jj856296.aspx
# operationId: Namespaces_Delete
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces delete" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
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
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Returns the description for the specified namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# operationId: Namespaces_Get
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces get" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
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
]: nothing -> record<properties: record<createdAt: string, critical: bool, dataCenter: string, enabled: bool, metricId: string, name: string, namespaceType: string, provisioningState: string, region: string, scaleUnit: string, serviceBusEndpoint: string, status: string, subscriptionId: string, updatedAt: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Patches the existing namespace
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# operationId: Namespaces_Patch
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces update" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
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
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<createdAt: string, critical: bool, dataCenter: string, enabled: bool, metricId: string, name: string, namespaceType: string, provisioningState: string, region: string, scaleUnit: string, serviceBusEndpoint: string, status: string, subscriptionId: string, updatedAt: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}") $qp)
  let req_body = {"sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates/Updates a service namespace. Once created, this namespace's resource manifest is immutable. This operation is idempotent.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}
# Docs: http://msdn.microsoft.com/en-us/library/windowsazure/jj856303.aspx
# operationId: Namespaces_CreateOrUpdate
# --properties shape: {createdAt?: string, critical?: bool, dataCenter?: string, enabled?: bool, name?: string, namespaceType?: "Messaging"|"NotificationHub", provisioningState?: string, region?: string, scaleUnit?: string, serviceBusEndpoint?: string, status?: string, subscriptionId?: string, updatedAt?: string}
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces create-or-update" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
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
  --properties: any # Namespace properties. — shape: {createdAt?: string, critical?: bool, dataCenter?: string, enabled?: bool, name?: string, namespaceType?: "Messaging"|"NotificationHub", provisioningState?: string, region?: string, scaleUnit?: string, serviceBusEndpoint?: string, status?: string, subscriptionId?: string, updatedAt?: string}
  location: string # Resource location
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<createdAt: string, critical: bool, dataCenter: string, enabled: bool, metricId: string, name: string, namespaceType: string, provisioningState: string, region: string, scaleUnit: string, serviceBusEndpoint: string, status: string, subscriptionId: string, updatedAt: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the authorization rules for a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules
# operationId: Namespaces_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules list" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/AuthorizationRules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a namespace authorization rule
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# operationId: Namespaces_DeleteAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules delete" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  authorization_rule_name: string
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
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/AuthorizationRules/{authorization_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets an authorization rule for a namespace by name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# operationId: Namespaces_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules get" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  authorization_rule_name: string
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
]: nothing -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/AuthorizationRules/{authorization_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates an authorization rule for a namespace
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}
# operationId: Namespaces_CreateOrUpdateAuthorizationRule
# --properties shape: {rights?: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules create-or-update" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  authorization_rule_name: string
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
  properties: any # SharedAccessAuthorizationRule properties. — shape: {rights?: list<string>}
]: any -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/AuthorizationRules/{authorization_rule_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the Primary and Secondary ConnectionStrings to the namespace
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}/listKeys
# operationId: Namespaces_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules-list-keys list" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  authorization_rule_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/AuthorizationRules/{authorization_rule_name}/listKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Regenerates the Primary/Secondary Keys to the Namespace Authorization Rule
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/AuthorizationRules/{authorizationRuleName}/regenerateKeys
# operationId: Namespaces_RegenerateKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-authorization-rules-regenerate-keys create" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  authorization_rule_name: string
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
  --policy-key: string # Name of the key that has to be regenerated for the Namespace/Notification Hub Authorization Rule. The value can be Primary Key/Secondary Key.
]: any -> record<keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/AuthorizationRules/{authorization_rule_name}/regenerateKeys") $qp)
  let req_body = {"policyKey": $policy_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Checks the availability of the given notificationHub in a namespace.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/checkNotificationHubAvailability
# operationId: NotificationHubs_CheckNotificationHubAvailability
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-check-notification-hub-availability check" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
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
  --is-availiable: oneof<nothing, bool> # True if the name is available and can be used to create new Namespace/NotificationHub. Otherwise false.
  --location: string # Resource location
  name: string # Resource name
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<isAvailiable: bool, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/checkNotificationHubAvailability") $qp)
  let req_body = {"isAvailiable": $is_availiable, "location": $location, "name": $name, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists the notification hubs associated with a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs
# operationId: NotificationHubs_List
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs list" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a notification hub associated with a namespace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_Delete
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs delete" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
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
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Lists the notification hubs associated with a namespace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_Get
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs get" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
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
]: nothing -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, authorizationRules: list<record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, name: string, registrationTtl: string, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Patch a NotificationHub in a namespace.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_Patch
# --properties shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs update" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
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
  --properties: any # NotificationHub properties. — shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
  --location: string # Resource location
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, authorizationRules: list<record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, name: string, registrationTtl: string, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates/Update a NotificationHub in a namespace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}
# operationId: NotificationHubs_CreateOrUpdate
# --properties shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
# --sku shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs create-or-update" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
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
  properties: any # NotificationHub properties. — shape: {admCredential?: any, apnsCredential?: any, authorizationRules?: list, baiduCredential?: any, gcmCredential?: any, mpnsCredential?: any, name?: string, registrationTtl?: string, wnsCredential?: any}
  --location: string # Resource location
  --sku: any # The Sku description for a namespace — shape: {capacity?: int, family?: string, name: "Free"|"Basic"|"Standard", size?: string, tier?: string}
  --tags: record # Resource tags
]: any -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, authorizationRules: list<record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, name: string, registrationTtl: string, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}") $qp)
  let req_body = {"properties": $properties, "location": $location, "sku": $sku, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the authorization rules for a NotificationHub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules
# operationId: NotificationHubs_ListAuthorizationRules
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules list" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, sku: record, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/AuthorizationRules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes a notificationHub authorization rule
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}
# operationId: NotificationHubs_DeleteAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules delete" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
  authorization_rule_name: string
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
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/AuthorizationRules/{authorization_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets an authorization rule for a NotificationHub by name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}
# operationId: NotificationHubs_GetAuthorizationRule
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules get" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
  authorization_rule_name: string
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
]: nothing -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/AuthorizationRules/{authorization_rule_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates/Updates an authorization rule for a NotificationHub
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}
# operationId: NotificationHubs_CreateOrUpdateAuthorizationRule
# --properties shape: {rights?: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules create-or-update" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
  authorization_rule_name: string
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
  properties: any # SharedAccessAuthorizationRule properties. — shape: {rights?: list<string>}
]: any -> record<properties: record<claimType: string, claimValue: string, createdTime: string, keyName: string, modifiedTime: string, primaryKey: string, revision: int, rights: list<string>, secondaryKey: string>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/AuthorizationRules/{authorization_rule_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the Primary and Secondary ConnectionStrings to the NotificationHub
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}/listKeys
# operationId: NotificationHubs_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules-list-keys list" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
  authorization_rule_name: string
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
]: nothing -> record<keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/AuthorizationRules/{authorization_rule_name}/listKeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Regenerates the Primary/Secondary Keys to the NotificationHub Authorization Rule
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/AuthorizationRules/{authorizationRuleName}/regenerateKeys
# operationId: NotificationHubs_RegenerateKeys
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-authorization-rules-regenerate-keys create" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
  authorization_rule_name: string
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
  --policy-key: string # Name of the key that has to be regenerated for the Namespace/Notification Hub Authorization Rule. The value can be Primary Key/Secondary Key.
]: any -> record<keyName: string, primaryConnectionString: string, primaryKey: string, secondaryConnectionString: string, secondaryKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  if ($authorization_rule_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationRuleName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name), authorization_rule_name: (encode-path-segment $authorization_rule_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/AuthorizationRules/{authorization_rule_name}/regenerateKeys") $qp)
  let req_body = {"policyKey": $policy_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# test send a push notification
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/debugsend
# operationId: NotificationHubs_DebugSend
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-debugsend send-debug" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
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
  --body: record
]: any -> record<properties: record<failure: float, results: record, success: float>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/debugsend") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists the PNS Credentials associated with a notification hub .
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.NotificationHubs/namespaces/{namespaceName}/notificationHubs/{notificationHubName}/pnsCredentials
# operationId: NotificationHubs_GetPnsCredentials
export def "subscriptions-resource-groups-providers-microsoft-notification-hubs-namespaces-notification-hubs-pns-credentials get" [
  subscription_id: string
  resource_group_name: string
  namespace_name: string
  notification_hub_name: string
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
]: nothing -> record<properties: record<admCredential: record<properties: record>, apnsCredential: record<properties: record>, baiduCredential: record<properties: record>, gcmCredential: record<properties: record>, mpnsCredential: record<properties: record>, wnsCredential: record<properties: record>>, id: string, location: string, name: string, sku: record<capacity: int, family: string, name: string, size: string, tier: string>, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($namespace_name | is-empty) { error make --unspanned { msg: "path parameter 'namespaceName' must be non-empty" } }
  if ($notification_hub_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationHubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), namespace_name: (encode-path-segment $namespace_name), notification_hub_name: (encode-path-segment $notification_hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.NotificationHubs/namespaces/{namespace_name}/notificationHubs/{notification_hub_name}/pnsCredentials") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}
