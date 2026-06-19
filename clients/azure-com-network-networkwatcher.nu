# Auto-generated client for NetworkManagementClient v2019-07-01
# Source: https://api.apis.guru/v2/specs/azure.com/network-networkWatcher/2019-07-01/swagger.json
# Auth: --token flag or $env.NETWORKMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NETWORKMANAGEMENTCLIENT_TOKEN | default "" }
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

# Completers for enum parameters
def protocol-completer [] { ["Http" "Https" "Icmp" "Tcp"] }
def direction-completer [] { ["Inbound" "Outbound"] }
def protocol-completer-1 [] { ["TCP" "UDP"] }
def verbosity-level-completer [] { ["Full" "Minimum" "Normal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-providers-microsoft-network-network-watchers list" } } | get name | first)
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

# Gets all network watchers by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Network/networkWatchers
# operationId: NetworkWatchers_ListAll
export def "subscriptions-providers-microsoft-network-network-watchers list" [
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
  --api-version: string # Client API version.
]: nothing -> record<value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Network/networkWatchers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets all network watchers by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers
# operationId: NetworkWatchers_List
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers list" [
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
  --api-version: string # Client API version.
]: nothing -> record<value: table<etag: string, properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the specified network watcher resource.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}
# operationId: NetworkWatchers_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers delete" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the specified network watcher by resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}
# operationId: NetworkWatchers_Get
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, properties: record<provisioningState: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates a network watcher tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}
# operationId: NetworkWatchers_UpdateTags
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers update-tags" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<provisioningState: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}") $qp)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates or updates a network watcher in the specified resource group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}
# operationId: NetworkWatchers_CreateOrUpdate
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers create-or-update" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --etag: string # A unique read-only string that changes whenever the resource is updated.
  --properties: any # The network watcher properties.
  --id: string # Resource ID.
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<etag: string, properties: record<provisioningState: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}") $qp)
  let req_body = {"etag": $etag, "properties": $properties, "id": $id, "location": $location, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all available internet service providers for a specified Azure region.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/availableProvidersList
# operationId: NetworkWatchers_ListAvailableProviders
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-available-providers-list list" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --azure-locations: list<string> # A list of Azure regions.
  --city: string # The city or town for available providers list.
  --country: string # The country for available providers list.
  --state: string # The state for available providers list.
]: any -> record<countries: table<countryName: string, providers: list, states: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/availableProvidersList") $qp)
  let req_body = {"azureLocations": $azure_locations, "city": $city, "country": $country, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the relative latency score for internet service providers from a specified location to Azure regions.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/azureReachabilityReport
# operationId: NetworkWatchers_GetAzureReachabilityReport
# --providerLocation shape: {city?: string, country: string, state?: string}
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-azure-reachability-report get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --azure-locations: list<string> # Optional Azure regions to scope the query to.
  end_time: string # The end time for the Azure reachability report. (format: date-time)
  provider_location: any # Parameters that define a geographic location. — shape: {city?: string, country: string, state?: string}
  --providers: list<string> # List of Internet service providers.
  start_time: string # The start time for the Azure reachability report. (format: date-time)
]: any -> record<aggregationLevel: string, providerLocation: record<city: string, country: string, state: string>, reachabilityReport: table<azureLocation: string, latencies: list, provider: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/azureReachabilityReport") $qp)
  let req_body = {"azureLocations": $azure_locations, "endTime": $end_time, "providerLocation": $provider_location, "providers": $providers, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Configures flow log and traffic analytics (optional) on a specified resource.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/configureFlowLog
# operationId: NetworkWatchers_SetFlowLogConfiguration
# --flowAnalyticsConfiguration shape: {networkWatcherFlowAnalyticsConfiguration: any}
# --properties shape: {enabled: bool, format?: any, retentionPolicy?: any, storageId: string}
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-configure-flow-log update-configuration" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --flow-analytics-configuration: any # Parameters that define the configuration of traffic analytics. — shape: {networkWatcherFlowAnalyticsConfiguration: any}
  properties: any # Parameters that define the configuration of flow log. — shape: {enabled: bool, format?: any, retentionPolicy?: any, storageId: string}
  target_resource_id: string # The ID of the resource to configure for flow log and traffic analytics (optional) .
]: any -> record<flowAnalyticsConfiguration: record<networkWatcherFlowAnalyticsConfiguration: record<enabled: bool, trafficAnalyticsInterval: int, workspaceId: string, workspaceRegion: string, workspaceResourceId: string>>, properties: record<enabled: bool, format: record<type: string, version: int>, retentionPolicy: record<days: int, enabled: bool>, storageId: string>, targetResourceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/configureFlowLog") $qp)
  let req_body = {"flowAnalyticsConfiguration": $flow_analytics_configuration, "properties": $properties, "targetResourceId": $target_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Verifies the possibility of establishing a direct TCP connection from a virtual machine to a given endpoint including another VM or an arbitrary remote server.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/connectivityCheck
# operationId: NetworkWatchers_CheckConnectivity
# --destination shape: {address?: string, port?: int, resourceId?: string}
# --protocolConfiguration shape: {HTTPConfiguration?: any}
# --source shape: {port?: int, resourceId: string}
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-connectivity-check check" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  destination: any # Parameters that define destination of connection. — shape: {address?: string, port?: int, resourceId?: string}
  --protocol: string@protocol-completer # Network protocol.
  --protocol-configuration: any # Configuration of the protocol. — shape: {HTTPConfiguration?: any}
  --body-source: any # Parameters that define the source of the connection. — shape: {port?: int, resourceId: string}
]: any -> record<avgLatencyInMs: int, connectionStatus: string, hops: table<address: string, id: string, issues: list, nextHopIds: list, resourceId: string, type: string>, maxLatencyInMs: int, minLatencyInMs: int, probesFailed: int, probesSent: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/connectivityCheck") $qp)
  let req_body = {"destination": $destination, "protocol": $protocol, "protocolConfiguration": $protocol_configuration, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Verify IP flow from the specified VM to a location given the currently configured NSG rules.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/ipFlowVerify
# operationId: NetworkWatchers_VerifyIPFlow
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-ip-flow-verify verify" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  direction: string@direction-completer # The direction of the traffic.
  local_ip_address: string # The local IP address. Acceptable values are valid IPv4 addresses.
  local_port: string # The local port. Acceptable values are a single integer in the range (0-65535). Support for * for the source port, which depends on the direction.
  protocol: string@protocol-completer-1 # Protocol to be verified on.
  remote_ip_address: string # The remote IP address. Acceptable values are valid IPv4 addresses.
  remote_port: string # The remote port. Acceptable values are a single integer in the range (0-65535). Support for * for the source port, which depends on the direction.
  --target-nic-resource-id: string # The NIC ID. (If VM has multiple NICs and IP forwarding is enabled on any of them, then this parameter must be specified. Otherwise optional).
  target_resource_id: string # The ID of the target resource to perform next-hop on.
]: any -> record<access: string, ruleName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/ipFlowVerify") $qp)
  let req_body = {"direction": $direction, "localIPAddress": $local_ip_address, "localPort": $local_port, "protocol": $protocol, "remoteIPAddress": $remote_ip_address, "remotePort": $remote_port, "targetNicResourceId": $target_nic_resource_id, "targetResourceId": $target_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets Network Configuration Diagnostic data to help customers understand and debug network behavior. It provides detailed information on what security rules were applied to a specified traffic flow and the result of evaluating these rules. Customers must provide details of a flow like source, destination, protocol, etc. The API returns whether traffic was allowed or denied, the rules evaluated for the specified flow and the evaluation results.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/networkConfigurationDiagnostic
# operationId: NetworkWatchers_GetNetworkConfigurationDiagnostic
# --profiles item shape: {destination: string, destinationPort: string, direction: "Inbound"|"Outbound", protocol: string, source: string}
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-network-configuration-diagnostic get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  profiles: list # List of network configuration diagnostic profiles. — item shape: {destination: string, destinationPort: string, direction: "Inbound"|"Outbound", protocol: string, source: string}
  target_resource_id: string # The ID of the target resource to perform network configuration diagnostic. Valid options are VM, NetworkInterface, VMSS/NetworkInterface and Application Gateway.
  --verbosity-level: string@verbosity-level-completer # Verbosity level.
]: any -> record<results: table<networkSecurityGroupResult: record, profile: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/networkConfigurationDiagnostic") $qp)
  let req_body = {"profiles": $profiles, "targetResourceId": $target_resource_id, "verbosityLevel": $verbosity_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the next hop from the specified VM.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/nextHop
# operationId: NetworkWatchers_GetNextHop
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-next-hop get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  destination_ip_address: string # The destination IP address.
  source_ip_address: string # The source IP address.
  --target-nic-resource-id: string # The NIC ID. (If VM has multiple NICs and IP forwarding is enabled on any of the nics, then this parameter must be specified. Otherwise optional).
  target_resource_id: string # The resource identifier of the target resource against which the action is to be performed.
]: any -> record<nextHopIpAddress: string, nextHopType: string, routeTableId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/nextHop") $qp)
  let req_body = {"destinationIPAddress": $destination_ip_address, "sourceIPAddress": $source_ip_address, "targetNicResourceId": $target_nic_resource_id, "targetResourceId": $target_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Lists all packet capture sessions within the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/packetCaptures
# operationId: PacketCaptures_List
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-packet-captures list" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<value: table<etag: string, id: string, name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/packetCaptures") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the specified packet capture session.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/packetCaptures/{packetCaptureName}
# operationId: PacketCaptures_Delete
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-packet-captures delete" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  packet_capture_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  if ($packet_capture_name | is-empty) { error make --unspanned { msg: "path parameter 'packetCaptureName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name), packet_capture_name: (encode-path-segment $packet_capture_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/packetCaptures/{packet_capture_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a packet capture session by name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/packetCaptures/{packetCaptureName}
# operationId: PacketCaptures_Get
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-packet-captures get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  packet_capture_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<etag: string, id: string, name: string, properties: record<provisioningState: string, bytesToCapturePerPacket: int, filters: list<record>, storageLocation: record<filePath: string, storageId: string, storagePath: string>, target: string, timeLimitInSeconds: int, totalBytesPerSession: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  if ($packet_capture_name | is-empty) { error make --unspanned { msg: "path parameter 'packetCaptureName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name), packet_capture_name: (encode-path-segment $packet_capture_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/packetCaptures/{packet_capture_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Create and start a packet capture on the specified VM.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/packetCaptures/{packetCaptureName}
# operationId: PacketCaptures_Create
# --properties shape: {bytesToCapturePerPacket?: int, filters?: list, storageLocation: any, target: string, timeLimitInSeconds?: int, totalBytesPerSession?: int}
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-packet-captures create" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  packet_capture_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  properties: any # Parameters that define the create packet capture operation. — shape: {bytesToCapturePerPacket?: int, filters?: list, storageLocation: any, target: string, timeLimitInSeconds?: int, totalBytesPerSession?: int}
]: any -> record<etag: string, id: string, name: string, properties: record<provisioningState: string, bytesToCapturePerPacket: int, filters: list<record>, storageLocation: record<filePath: string, storageId: string, storagePath: string>, target: string, timeLimitInSeconds: int, totalBytesPerSession: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  if ($packet_capture_name | is-empty) { error make --unspanned { msg: "path parameter 'packetCaptureName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name), packet_capture_name: (encode-path-segment $packet_capture_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/packetCaptures/{packet_capture_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Query the status of a running packet capture session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/packetCaptures/{packetCaptureName}/queryStatus
# operationId: PacketCaptures_GetStatus
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-packet-captures-query-status get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  packet_capture_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<captureStartTime: string, id: string, name: string, packetCaptureError: list<string>, packetCaptureStatus: string, stopReason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  if ($packet_capture_name | is-empty) { error make --unspanned { msg: "path parameter 'packetCaptureName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name), packet_capture_name: (encode-path-segment $packet_capture_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/packetCaptures/{packet_capture_name}/queryStatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Stops a specified packet capture session.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/packetCaptures/{packetCaptureName}/stop
# operationId: PacketCaptures_Stop
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-packet-captures-stop stop" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  packet_capture_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
]: nothing -> record<error: record<code: string, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  if ($packet_capture_name | is-empty) { error make --unspanned { msg: "path parameter 'packetCaptureName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name), packet_capture_name: (encode-path-segment $packet_capture_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/packetCaptures/{packet_capture_name}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Queries status of flow log and traffic analytics (optional) on a specified resource.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/queryFlowLogStatus
# operationId: NetworkWatchers_GetFlowLogStatus
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-query-flow-log-status get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  target_resource_id: string # The target resource where getting the flow log and traffic analytics (optional) status.
]: any -> record<flowAnalyticsConfiguration: record<networkWatcherFlowAnalyticsConfiguration: record<enabled: bool, trafficAnalyticsInterval: int, workspaceId: string, workspaceRegion: string, workspaceResourceId: string>>, properties: record<enabled: bool, format: record<type: string, version: int>, retentionPolicy: record<days: int, enabled: bool>, storageId: string>, targetResourceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/queryFlowLogStatus") $qp)
  let req_body = {"targetResourceId": $target_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get the last completed troubleshooting result on a specified resource.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/queryTroubleshootResult
# operationId: NetworkWatchers_GetTroubleshootingResult
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-query-troubleshoot-result get-troubleshooting" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  target_resource_id: string # The target resource ID to query the troubleshooting result.
]: any -> record<code: string, endTime: string, results: table<detail: string, id: string, reasonType: string, recommendedActions: list, summary: string>, startTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/queryTroubleshootResult") $qp)
  let req_body = {"targetResourceId": $target_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the configured and effective security group rules on the specified VM.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/securityGroupView
# operationId: NetworkWatchers_GetVMSecurityRules
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-security-group-view get-vm-rules" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  target_resource_id: string # ID of the target VM.
]: any -> record<networkInterfaces: table<id: string, securityRuleAssociations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/securityGroupView") $qp)
  let req_body = {"targetResourceId": $target_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the current network topology by resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/topology
# operationId: NetworkWatchers_GetTopology
# --targetSubnet shape: {id?: string}
# --targetVirtualNetwork shape: {id?: string}
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-topology get" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --target-resource-group-name: string # The name of the target resource group to perform topology on.
  --target-subnet: any # Reference to another subresource. — shape: {id?: string}
  --target-virtual-network: any # Reference to another subresource. — shape: {id?: string}
]: any -> record<createdDateTime: string, id: string, lastModified: string, resources: table<associations: list, id: string, location: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/topology") $qp)
  let req_body = {"targetResourceGroupName": $target_resource_group_name, "targetSubnet": $target_subnet, "targetVirtualNetwork": $target_virtual_network} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Initiate troubleshooting on a specified resource.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/networkWatchers/{networkWatcherName}/troubleshoot
# operationId: NetworkWatchers_GetTroubleshooting
# --properties shape: {storageId: string, storagePath: string}
export def "subscriptions-resource-groups-providers-microsoft-network-network-watchers-troubleshoot get-troubleshooting" [
  subscription_id: string
  resource_group_name: string
  network_watcher_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  properties: any # Storage location provided for troubleshoot. — shape: {storageId: string, storagePath: string}
  target_resource_id: string # The target resource to troubleshoot.
]: any -> record<code: string, endTime: string, results: table<detail: string, id: string, reasonType: string, recommendedActions: list, summary: string>, startTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($network_watcher_name | is-empty) { error make --unspanned { msg: "path parameter 'networkWatcherName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), network_watcher_name: (encode-path-segment $network_watcher_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Network/networkWatchers/{network_watcher_name}/troubleshoot") $qp)
  let req_body = {"properties": $properties, "targetResourceId": $target_resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}
