# Auto-generated client for Workload Monitor v2018-08-31-preview
# Source: https://api.apis.guru/v2/specs/azure.com/workloadmonitor-Microsoft.WorkloadMonitor/2018-08-31-preview/swagger.json
# Auth: --token flag or $env.WORKLOAD_MONITOR_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o WORKLOAD_MONITOR_TOKEN | default "" }
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

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["2018-08-31-preview"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-workload-monitor-operations list" } } | get name | first)
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

# Gets the details of all operations possible on the resource provider.
#
# GET /providers/Microsoft.WorkloadMonitor/operations
# operationId: Operations_List
export def "providers-microsoft-workload-monitor-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --skiptoken: string # The page-continuation token to use with a paged version of this API.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.WorkloadMonitor/operations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$skiptoken": $skiptoken} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get subscription wide details of components.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.WorkloadMonitor/componentsSummary
# operationId: ComponentsSummary_List
export def "subscriptions-providers-microsoft-workload-monitor-components-summary list" [
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
  --api-version: string@api-version-completer # The API version to use for this operation.
  --select: string # Properties to be returned in the response.
  --filter: string # Filter to be applied on the operation.
  --apply: string # Apply aggregation.
  --orderby: string # Sort the result on one or more properties.
  --expand: string # Include properties inline in the response.
  --top: string # Limit the result to the specified number of rows.
  --skiptoken: string # The page-continuation token to use with a paged version of this API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.WorkloadMonitor/componentsSummary") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select, "$filter": $filter, "$apply": $apply, "$orderby": $orderby, "$expand": $expand, "$top": $top, "$skiptoken": $skiptoken} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get subscription wide health instances.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.WorkloadMonitor/monitorInstancesSummary
# operationId: MonitorInstancesSummary_List
export def "subscriptions-providers-microsoft-workload-monitor-monitor-instances-summary list" [
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
  --api-version: string@api-version-completer # The API version to use for this operation.
  --select: string # Properties to be returned in the response.
  --filter: string # Filter to be applied on the operation.
  --apply: string # Apply aggregation.
  --orderby: string # Sort the result on one or more properties.
  --expand: string # Include properties inline in the response.
  --top: string # Limit the result to the specified number of rows.
  --skiptoken: string # The page-continuation token to use with a paged version of this API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.WorkloadMonitor/monitorInstancesSummary") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select, "$filter": $filter, "$apply": $apply, "$orderby": $orderby, "$expand": $expand, "$top": $top, "$skiptoken": $skiptoken} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get list of components for a resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/components
# operationId: Components_ListByResource
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-components list" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --select: string # Properties to be returned in the response.
  --filter: string # Filter to be applied on the operation.
  --apply: string # Apply aggregation.
  --orderby: string # Sort the result on one or more properties.
  --expand: string # Include properties inline in the response.
  --top: string # Limit the result to the specified number of rows.
  --skiptoken: string # The page-continuation token to use with a paged version of this API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/components") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select, "$filter": $filter, "$apply": $apply, "$orderby": $orderby, "$expand": $expand, "$top": $top, "$skiptoken": $skiptoken} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details of a component.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/components/{componentId}
# operationId: Components_Get
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-components get" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  component_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --select: string # Properties to be returned in the response.
  --expand: string # Include properties inline in the response.
]: nothing -> record<etag: string, properties: record<aggregateProperties: record, children: list<any>, componentName: string, componentTypeGroupCategory: string, componentTypeId: string, componentTypeName: string, healthState: string, healthStateCategory: string, healthStateChangesEndTime: string, healthStateChangesStartTime: string, lastHealthStateChangeTime: string, solutionId: string, vmId: string, vmName: string, vmTags: record, workloadType: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($component_id | is-empty) { error make --unspanned { msg: "path parameter 'componentId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name), component_id: (encode-path-segment $component_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/components/{component_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select, "$expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get list of monitor instances for a resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/monitorInstances
# operationId: MonitorInstances_ListByResource
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-monitor-instances list" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --select: string # Properties to be returned in the response.
  --filter: string # Filter to be applied on the operation.
  --apply: string # Apply aggregation.
  --orderby: string # Sort the result on one or more properties.
  --expand: string # Include properties inline in the response.
  --top: string # Limit the result to the specified number of rows.
  --skiptoken: string # The page-continuation token to use with a paged version of this API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$apply" $apply "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/monitorInstances") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select, "$filter": $filter, "$apply": $apply, "$orderby": $orderby, "$expand": $expand, "$top": $top, "$skiptoken": $skiptoken} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details of a monitorInstance.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/monitorInstances/{monitorInstanceId}
# operationId: MonitorInstances_Get
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-monitor-instances get" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  monitor_instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --select: string # Properties to be returned in the response.
  --expand: string # Include properties inline in the response.
]: nothing -> record<etag: string, properties: record<aggregateProperties: record, alertGeneration: string, children: list<any>, componentId: string, componentName: string, componentTypeId: string, componentTypeName: string, healthState: string, healthStateCategory: string, healthStateChanges: list<record>, healthStateChangesEndTime: string, healthStateChangesStartTime: string, lastHealthStateChangeTime: string, monitorCategory: string, monitorId: string, monitorName: string, monitorType: string, solutionId: string, workloadType: string, workspaceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($monitor_instance_id | is-empty) { error make --unspanned { msg: "path parameter 'monitorInstanceId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name), monitor_instance_id: (encode-path-segment $monitor_instance_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/monitorInstances/{monitor_instance_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$select": $select, "$expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get list of a monitors of a resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/monitors
# operationId: Monitors_ListByResource
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-monitors list" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --filter: string # Filter to be applied on the operation.
  --skiptoken: string # The page-continuation token to use with a paged version of this API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/monitors") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$skiptoken": $skiptoken} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details of a single monitor.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/monitors/{monitorId}
# operationId: Monitors_Get
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-monitors get" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  monitor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
]: nothing -> record<etag: string, properties: record<alertGeneration: string, componentTypeDisplayName: string, componentTypeId: string, componentTypeName: string, criteria: list<record>, description: string, documentationURL: string, frequency: int, lookbackDuration: int, monitorCategory: string, monitorDisplayName: string, monitorId: string, monitorName: string, monitorState: string, monitorType: string, parentMonitorDisplayName: string, parentMonitorName: string, signalName: string, signalType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($monitor_id | is-empty) { error make --unspanned { msg: "path parameter 'monitorId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name), monitor_id: (encode-path-segment $monitor_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/monitors/{monitor_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Monitor's configuration.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/monitors/{monitorId}
# operationId: Monitors_Update
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-monitors update" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  monitor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --properties: record # Model for properties of a Monitor.
]: any -> record<etag: string, properties: record<alertGeneration: string, componentTypeDisplayName: string, componentTypeId: string, componentTypeName: string, criteria: list<record>, description: string, documentationURL: string, frequency: int, lookbackDuration: int, monitorCategory: string, monitorDisplayName: string, monitorId: string, monitorName: string, monitorState: string, monitorType: string, parentMonitorDisplayName: string, parentMonitorName: string, signalName: string, signalType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($monitor_id | is-empty) { error make --unspanned { msg: "path parameter 'monitorId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name), monitor_id: (encode-path-segment $monitor_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/monitors/{monitor_id}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get list of notification settings for a resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/notificationSettings
# operationId: NotificationSettings_ListByResource
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-notification-settings list" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --skiptoken: string # The page-continuation token to use with a paged version of this API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/notificationSettings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$skiptoken": $skiptoken} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a of notification setting for a resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/notificationSettings/{notificationSettingName}
# operationId: NotificationSettings_Get
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-notification-settings get" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  notification_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
]: nothing -> record<etag: string, properties: record<actionGroupResourceIds: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($notification_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name), notification_setting_name: (encode-path-segment $notification_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/notificationSettings/{notification_setting_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update notification settings for a resource.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceNamespace}/{resourceType}/{resourceName}/providers/Microsoft.WorkloadMonitor/notificationSettings/{notificationSettingName}
# operationId: NotificationSettings_Update
export def "subscriptions-resource-groups-providers-providers-microsoft-workload-monitor-notification-settings update" [
  subscription_id: string
  resource_group_name: string
  resource_namespace: string
  resource_type: string
  resource_name: string
  notification_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The API version to use for this operation.
  --properties: record # Model for properties of a NotificationSetting.
]: any -> record<etag: string, properties: record<actionGroupResourceIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_namespace | is-empty) { error make --unspanned { msg: "path parameter 'resourceNamespace' must be non-empty" } }
  if ($resource_type | is-empty) { error make --unspanned { msg: "path parameter 'resourceType' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($notification_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'notificationSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_namespace: (encode-path-segment $resource_namespace), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name), notification_setting_name: (encode-path-segment $notification_setting_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/{resource_namespace}/{resource_type}/{resource_name}/providers/Microsoft.WorkloadMonitor/notificationSettings/{notification_setting_name}") $qp $auth.query)
  let req_body = {"properties": $properties} | compact
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
