# Auto-generated client for Service Map v2015-11-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/service-map-arm-service-map/2015-11-01-preview/swagger.json
# Auth: --token flag or $env.SERVICE_MAP_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SERVICE_MAP_TOKEN | default "" }
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
def kind-completer [] { ["map:machine-group-dependency" "map:machine-list-dependency" "map:single-machine-dependency"] }
def kind-completer-1 [] { ["clientGroup" "machine" "machineGroup" "port" "process"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-client-groups get" } } | get name | first)
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

# Retrieves the specified client group
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/clientGroups/{clientGroupName}
# operationId: ClientGroups_Get
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-client-groups get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  client_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<properties: record<clientsOf: record<id: string, kind: string, name: string, type: string>>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), client_group_name: (encode-path-segment $client_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/clientGroups/{client_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the members of the client group during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/clientGroups/{clientGroupName}/members
# operationId: ClientGroups_ListMembers
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-client-groups-members list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  client_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
  --top: int # Page size to use. When not specified, the default page size is 100 records. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), client_group_name: (encode-path-segment $client_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/clientGroups/{client_group_name}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the approximate number of members in the client group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/clientGroups/{clientGroupName}/membersCount
# operationId: ClientGroups_GetMembersCount
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-client-groups-members-count get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  client_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<accuracy: string, count: int, endTime: string, groupId: string, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), client_group_name: (encode-path-segment $client_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/clientGroups/{client_group_name}/membersCount") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates the specified map.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/generateMap
# Discriminator (request): kind
# operationId: Maps_Generate
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-generate-map generate" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --end-time: string # Map interval end time. (format: date-time)
  kind: string@kind-completer # The type of map to create.
  --start-time: string # Map interval start time. (format: date-time)
]: any -> record<endTime: string, map: record<edges: record<acceptors: list, connections: list>, nodes: record<clientGroups: list, machines: list, ports: list, processes: list>>, startTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/generateMap") $qp)
  let req_body = {"endTime": $end_time, "kind": $kind, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns all machine groups during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machineGroups
# operationId: MachineGroups_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machine-groups list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new machine group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machineGroups
# operationId: MachineGroups_Create
# --properties shape: {count?: int, displayName: string, groupType?: "unknown"|"azure-cs"|"azure-sf"|"azure-vmss"|"user-static", machines?: list}
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machine-groups create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --etag: string # Resource ETAG.
  --properties: record # Resource properties. — shape: {count?: int, displayName: string, groupType?: "unknown"|"azure-cs"|"azure-sf"|"azure-vmss"|"user-static", machines?: list}
  kind: string@kind-completer-1 # Additional resource type qualifier.
]: any -> record<etag: string, properties: record<count: int, displayName: string, groupType: string, machines: list<record>>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups") $qp)
  let req_body = {"etag": $etag, "properties": $properties, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified Machine Group.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machineGroups/{machineGroupName}
# operationId: MachineGroups_Delete
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machine-groups delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_group_name: (encode-path-segment $machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups/{machine_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the specified machine group as it existed during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machineGroups/{machineGroupName}
# operationId: MachineGroups_Get
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machine-groups get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<etag: string, properties: record<count: int, displayName: string, groupType: string, machines: list<record>>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_group_name: (encode-path-segment $machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups/{machine_group_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a machine group.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machineGroups/{machineGroupName}
# operationId: MachineGroups_Update
# --properties shape: {count?: int, displayName: string, groupType?: "unknown"|"azure-cs"|"azure-sf"|"azure-vmss"|"user-static", machines?: list}
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machine-groups update" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --etag: string # Resource ETAG.
  --properties: record # Resource properties. — shape: {count?: int, displayName: string, groupType?: "unknown"|"azure-cs"|"azure-sf"|"azure-vmss"|"user-static", machines?: list}
  kind: string@kind-completer-1 # Additional resource type qualifier.
]: any -> record<etag: string, properties: record<count: int, displayName: string, groupType: string, machines: list<record>>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_group_name: (encode-path-segment $machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups/{machine_group_name}") $qp)
  let req_body = {"etag": $etag, "properties": $properties, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a collection of machines matching the specified conditions. The returned collection represents either machines that are active/live during the specified interval of time (`live=true` and `startTime`/`endTime` are specified) or that are known to have existed at or some time prior to the specified point in time (`live=false` and `timestamp` is specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines
# operationId: Machines_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --live: oneof<nothing, bool> # Specifies whether to return live resources (true) or inventory resources (false). Defaults to **true**. When retrieving live resources, the start time (`startTime`) and end time (`endTime`) of the desired interval should be included. When retrieving inventory resources, an optional timestamp (`timestamp`) parameter can be specified to return the version of each resource closest (not-after) that timestamp. (default: true)
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
  --timestamp: string # UTC date and time specifying a time instance relative to which to evaluate each machine resource. Only applies when `live=false`. When not specified, the service uses DateTime.UtcNow. (format: date-time)
  --top: int # Page size to use. When not specified, the default page size is 100 records. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "live" $live "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the specified machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}
# operationId: Machines_Get
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --timestamp: string # UTC date and time specifying a time instance relative to which to evaluate the machine resource. When not specified, the service uses DateTime.UtcNow. (format: date-time)
]: nothing -> record<properties: record<agent: record<agentId: string, clockGranularity: int, dependencyAgentId: string, dependencyAgentRevision: string, dependencyAgentVersion: string, rebootStatus: string>, bootTime: string, computerName: string, displayName: string, fullyQualifiedDomainName: string, hosting: record<kind: string, provider: string>, hypervisor: record<hypervisorType: string, nativeHostMachineId: string>, monitoringState: string, networking: record<defaultIpv4Gateways: list, dnsNames: list, ipv4Interfaces: list, ipv6Interfaces: list, macAddresses: list>, operatingSystem: record<bitness: string, family: string, fullName: string>, resources: record<cpuSpeed: int, cpuSpeedAccuracy: string, cpus: int, physicalMemory: int>, timestamp: string, timezone: record<fullName: string>, virtualMachine: record<nativeHostMachineId: string, nativeMachineId: string, virtualMachineName: string, virtualMachineType: string>, virtualizationState: string>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of connections terminating or originating at the specified machine
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/connections
# operationId: Machines_ListConnections
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-connections list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtains the liveness status of the machine during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/liveness
# operationId: Machines_GetLiveness
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-liveness get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<endTime: string, live: bool, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/liveness") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of machine groups this machine belongs to during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/machineGroups
# operationId: Machines_ListMachineGroupMembership
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-machine-groups list-membership" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/machineGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of live ports on the specified machine during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/ports
# operationId: Machines_ListPorts
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-ports list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the specified port. The port must be live during the specified time interval. If the port is not live during the interval, status 404 (Not Found) is returned.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/ports/{portName}
# operationId: Ports_Get
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-ports get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  port_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<properties: record<displayName: string, ipAddress: string, machine: record<id: string, kind: string, name: string, type: string>, monitoringState: string, portNumber: int>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of processes accepting on the specified port
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/ports/{portName}/acceptingProcesses
# operationId: Ports_ListAcceptingProcesses
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-ports-accepting-processes list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  port_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}/acceptingProcesses") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of connections established via the specified port.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/ports/{portName}/connections
# operationId: Ports_ListConnections
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-ports-connections list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  port_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtains the liveness status of the port during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/ports/{portName}/liveness
# operationId: Ports_GetLiveness
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-ports-liveness get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  port_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<endTime: string, live: bool, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}/liveness") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of processes on the specified machine matching the specified conditions. The returned collection represents either processes that are active/live during the specified interval of time (`live=true` and `startTime`/`endTime` are specified) or that are known to have existed at or some time prior to the specified point in time (`live=false` and `timestamp` is specified).
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/processes
# operationId: Machines_ListProcesses
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-processes list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --live: oneof<nothing, bool> # Specifies whether to return live resources (true) or inventory resources (false). Defaults to **true**. When retrieving live resources, the start time (`startTime`) and end time (`endTime`) of the desired interval should be included. When retrieving inventory resources, an optional timestamp (`timestamp`) parameter can be specified to return the version of each resource closest (not-after) that timestamp. (default: true)
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
  --timestamp: string # UTC date and time specifying a time instance relative to which to evaluate all process resource. Only applies when `live=false`. When not specified, the service uses DateTime.UtcNow. (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "live" $live "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the specified process.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/processes/{processName}
# operationId: Processes_Get
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-processes get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  process_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --timestamp: string # UTC date and time specifying a time instance relative to which to evaluate a resource. When not specified, the service uses DateTime.UtcNow. (format: date-time)
]: nothing -> record<properties: record<acceptorOf: record<id: string, kind: string, name: string, type: string>, clientOf: record<id: string, kind: string, name: string, type: string>, details: record<commandLine: string, companyName: string, description: string, executablePath: string, fileVersion: string, firstPid: int, internalName: string, persistentKey: string, poolId: int, productName: string, productVersion: string, services: list, workingDirectory: string, zoneName: string>, displayName: string, executableName: string, group: string, hosting: record<kind: string, provider: string>, machine: record<id: string, kind: string, name: string, type: string>, monitoringState: string, role: string, startTime: string, timestamp: string, user: record<userDomain: string, userName: string>>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of ports on which this process is accepting
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/processes/{processName}/acceptingPorts
# operationId: Processes_ListAcceptingPorts
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-processes-accepting-ports list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  process_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}/acceptingPorts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a collection of connections terminating or originating at the specified process
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/processes/{processName}/connections
# operationId: Processes_ListConnections
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-processes-connections list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  process_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}/connections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtains the liveness status of the process during the specified time interval.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/machines/{machineName}/processes/{processName}/liveness
# operationId: Processes_GetLiveness
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-machines-processes-liveness get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  machine_name: string
  process_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<endTime: string, live: bool, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}/liveness") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns summary information about the machines in the workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}/features/serviceMap/summaries/machines
# operationId: Summaries_GetMachines
export def "subscriptions-resource-groups-providers-microsoft-operational-insights-workspaces-features-service-map-summaries-machines get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<properties: record<live: int, os: record<linux: int, windows: int>, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/summaries/machines") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
