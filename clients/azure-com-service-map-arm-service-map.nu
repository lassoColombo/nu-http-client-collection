# Auto-generated client for Service Map v2015-11-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/service-map-arm-service-map/2015-11-01-preview/swagger.json
# Auth: --token flag or $env.SERVICE_MAP_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SERVICE_MAP_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def kind-completer [] { ["map:machine-group-dependency" "map:machine-list-dependency" "map:single-machine-dependency"] }
def kind-completer-1 [] { ["clientGroup" "machine" "machineGroup" "port" "process"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<properties: record<clientsOf: record<id: string, kind: string, name: string, type: string>>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($client_group_name | is-empty) { error make --unspanned { msg: "path parameter 'clientGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), client_group_name: (encode-path-segment $client_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/clientGroups/{client_group_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
  --top: int # Page size to use. When not specified, the default page size is 100 records. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($client_group_name | is-empty) { error make --unspanned { msg: "path parameter 'clientGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), client_group_name: (encode-path-segment $client_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/clientGroups/{client_group_name}/members") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<accuracy: string, count: int, endTime: string, groupId: string, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($client_group_name | is-empty) { error make --unspanned { msg: "path parameter 'clientGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), client_group_name: (encode-path-segment $client_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/clientGroups/{client_group_name}/membersCount") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --end-time: string # Map interval end time. (format: date-time)
  kind: string@kind-completer # The type of map to create.
  --start-time: string # Map interval start time. (format: date-time)
]: any -> record<endTime: string, map: record<edges: record<acceptors: list, connections: list>, nodes: record<clientGroups: list, machines: list, ports: list, processes: list>>, startTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/generateMap") $qp $auth.query)
  let req_body = {"endTime": $end_time, "kind": $kind, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --etag: string # Resource ETAG.
  --properties: record # Resource properties. — shape: {count?: int, displayName: string, groupType?: "unknown"|"azure-cs"|"azure-sf"|"azure-vmss"|"user-static", machines?: list}
  kind: string@kind-completer-1 # Additional resource type qualifier.
]: any -> record<etag: string, properties: record<count: int, displayName: string, groupType: string, machines: list<record>>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'machineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_group_name: (encode-path-segment $machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups/{machine_group_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<etag: string, properties: record<count: int, displayName: string, groupType: string, machines: list<record>>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'machineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_group_name: (encode-path-segment $machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups/{machine_group_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --etag: string # Resource ETAG.
  --properties: record # Resource properties. — shape: {count?: int, displayName: string, groupType?: "unknown"|"azure-cs"|"azure-sf"|"azure-vmss"|"user-static", machines?: list}
  kind: string@kind-completer-1 # Additional resource type qualifier.
]: any -> record<etag: string, properties: record<count: int, displayName: string, groupType: string, machines: list<record>>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_group_name | is-empty) { error make --unspanned { msg: "path parameter 'machineGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_group_name: (encode-path-segment $machine_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machineGroups/{machine_group_name}") $qp $auth.query)
  let req_body = {"etag": $etag, "properties": $properties, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "live" $live "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "live": $live, "startTime": $start_time, "endTime": $end_time, "timestamp": $timestamp, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --timestamp: string # UTC date and time specifying a time instance relative to which to evaluate the machine resource. When not specified, the service uses DateTime.UtcNow. (format: date-time)
]: nothing -> record<properties: record<agent: record<agentId: string, clockGranularity: int, dependencyAgentId: string, dependencyAgentRevision: string, dependencyAgentVersion: string, rebootStatus: string>, bootTime: string, computerName: string, displayName: string, fullyQualifiedDomainName: string, hosting: record<kind: string, provider: string>, hypervisor: record<hypervisorType: string, nativeHostMachineId: string>, monitoringState: string, networking: record<defaultIpv4Gateways: list, dnsNames: list, ipv4Interfaces: list, ipv6Interfaces: list, macAddresses: list>, operatingSystem: record<bitness: string, family: string, fullName: string>, resources: record<cpuSpeed: int, cpuSpeedAccuracy: string, cpus: int, physicalMemory: int>, timestamp: string, timezone: record<fullName: string>, virtualMachine: record<nativeHostMachineId: string, nativeMachineId: string, virtualMachineName: string, virtualMachineType: string>, virtualizationState: string>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/connections") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<endTime: string, live: bool, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/liveness") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/machineGroups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<properties: record<displayName: string, ipAddress: string, machine: record<id: string, kind: string, name: string, type: string>, monitoringState: string, portNumber: int>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($port_name | is-empty) { error make --unspanned { msg: "path parameter 'portName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($port_name | is-empty) { error make --unspanned { msg: "path parameter 'portName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}/acceptingProcesses") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($port_name | is-empty) { error make --unspanned { msg: "path parameter 'portName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}/connections") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<endTime: string, live: bool, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($port_name | is-empty) { error make --unspanned { msg: "path parameter 'portName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), port_name: (encode-path-segment $port_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/ports/{port_name}/liveness") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --live: oneof<nothing, bool> # Specifies whether to return live resources (true) or inventory resources (false). Defaults to **true**. When retrieving live resources, the start time (`startTime`) and end time (`endTime`) of the desired interval should be included. When retrieving inventory resources, an optional timestamp (`timestamp`) parameter can be specified to return the version of each resource closest (not-after) that timestamp. (default: true)
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
  --timestamp: string # UTC date and time specifying a time instance relative to which to evaluate all process resource. Only applies when `live=false`. When not specified, the service uses DateTime.UtcNow. (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "live" $live "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "live": $live, "startTime": $start_time, "endTime": $end_time, "timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --timestamp: string # UTC date and time specifying a time instance relative to which to evaluate a resource. When not specified, the service uses DateTime.UtcNow. (format: date-time)
]: nothing -> record<properties: record<acceptorOf: record<id: string, kind: string, name: string, type: string>, clientOf: record<id: string, kind: string, name: string, type: string>, details: record<commandLine: string, companyName: string, description: string, executablePath: string, fileVersion: string, firstPid: int, internalName: string, persistentKey: string, poolId: int, productName: string, productVersion: string, services: list, workingDirectory: string, zoneName: string>, displayName: string, executableName: string, group: string, hosting: record<kind: string, provider: string>, machine: record<id: string, kind: string, name: string, type: string>, monitoringState: string, role: string, startTime: string, timestamp: string, user: record<userDomain: string, userName: string>>, etag: string, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($process_name | is-empty) { error make --unspanned { msg: "path parameter 'processName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($process_name | is-empty) { error make --unspanned { msg: "path parameter 'processName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}/acceptingPorts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<nextLink: string, value: table<properties: record, kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($process_name | is-empty) { error make --unspanned { msg: "path parameter 'processName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}/connections") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<endTime: string, live: bool, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($machine_name | is-empty) { error make --unspanned { msg: "path parameter 'machineName' must be non-empty" } }
  if ($process_name | is-empty) { error make --unspanned { msg: "path parameter 'processName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), machine_name: (encode-path-segment $machine_name), process_name: (encode-path-segment $process_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/machines/{machine_name}/processes/{process_name}/liveness") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # API version.
  --start-time: string # UTC date and time specifying the start time of an interval. When not specified the service uses DateTime.UtcNow - 10m (format: date-time)
  --end-time: string # UTC date and time specifying the end time of an interval. When not specified the service uses DateTime.UtcNow (format: date-time)
]: nothing -> record<properties: record<live: int, os: record<linux: int, windows: int>, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.OperationalInsights/workspaces/{workspace_name}/features/serviceMap/summaries/machines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "startTime": $start_time, "endTime": $end_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
