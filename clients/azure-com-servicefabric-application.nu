# Auto-generated client for ServiceFabricManagementClient v2019-03-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/servicefabric-application/2019-03-01-preview/swagger.json
# Auth: --token flag or $env.SERVICEFABRICMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SERVICEFABRICMANAGEMENTCLIENT_TOKEN | default "" }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["2019-03-01-preview"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-service-fabric-operations list" } } | get name | first)
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

# Lists all of the available Service Fabric resource provider API operations.
#
# GET /providers/Microsoft.ServiceFabric/operations
# operationId: Operations_List
export def "providers-microsoft-service-fabric-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The version of the Service Fabric resource provider API
]: nothing -> record<nextLink: string, value: table<display: record, name: string, nextLink: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.ServiceFabric/operations" $qp $auth.query)
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

# Gets the list of application type name resources created in the specified Service Fabric cluster resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes
# operationId: ApplicationTypes_List
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types list" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes") $qp $auth.query)
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

# Deletes a Service Fabric application type name resource.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes/{applicationTypeName}
# operationId: ApplicationTypes_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types delete" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_type_name: (encode-path-segment $application_type_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes/{application_type_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202 204]
}

# Gets a Service Fabric application type name resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes/{applicationTypeName}
# operationId: ApplicationTypes_Get
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types get" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<properties: record<provisioningState: string>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_type_name: (encode-path-segment $application_type_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes/{application_type_name}") $qp $auth.query)
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

# Creates or updates a Service Fabric application type name resource.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes/{applicationTypeName}
# operationId: ApplicationTypes_Create
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types create" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
  --properties: any # The application type name properties
  --location: string # Azure resource location.
  --tags: record # Azure resource tags.
]: any -> record<properties: record<provisioningState: string>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_type_name: (encode-path-segment $application_type_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes/{application_type_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
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

# Gets the list of application type version resources created in the specified Service Fabric application type name resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes/{applicationTypeName}/versions
# operationId: ApplicationTypeVersions_List
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types-versions list" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_type_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_type_name: (encode-path-segment $application_type_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes/{application_type_name}/versions") $qp $auth.query)
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

# Deletes a Service Fabric application type version resource.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes/{applicationTypeName}/versions/{version}
# operationId: ApplicationTypeVersions_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types-versions delete" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_type_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_type_name: (encode-path-segment $application_type_name), version: (encode-path-segment $version)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes/{application_type_name}/versions/{version}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202 204]
}

# Gets a Service Fabric application type version resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes/{applicationTypeName}/versions/{version}
# operationId: ApplicationTypeVersions_Get
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types-versions get" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_type_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<properties: record<appPackageUrl: string, defaultParameterList: record, provisioningState: string>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_type_name: (encode-path-segment $application_type_name), version: (encode-path-segment $version)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes/{application_type_name}/versions/{version}") $qp $auth.query)
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

# Creates or updates a Service Fabric application type version resource.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applicationTypes/{applicationTypeName}/versions/{version}
# operationId: ApplicationTypeVersions_Create
# --properties shape: {appPackageUrl: string, defaultParameterList?: record}
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-application-types-versions create" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_type_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
  --properties: any # The properties of the application type version resource. — shape: {appPackageUrl: string, defaultParameterList?: record}
  --location: string # Azure resource location.
  --tags: record # Azure resource tags.
]: any -> record<properties: record<appPackageUrl: string, defaultParameterList: record, provisioningState: string>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_type_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationTypeName' must be non-empty" } }
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_type_name: (encode-path-segment $application_type_name), version: (encode-path-segment $version)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applicationTypes/{application_type_name}/versions/{version}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets the list of application resources created in the specified Service Fabric cluster resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications
# operationId: Applications_List
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications list" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications") $qp $auth.query)
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

# Deletes a Service Fabric application resource.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}
# operationId: Applications_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications delete" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202 204]
}

# Gets a Service Fabric application resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}
# operationId: Applications_Get
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications get" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<properties: record<provisioningState: string, typeName: string, maximumNodes: int, metrics: list<record>, minimumNodes: int, parameters: record, removeApplicationCapacity: bool, typeVersion: string, upgradePolicy: record<applicationHealthPolicy: record, forceRestart: bool, rollingUpgradeMonitoringPolicy: record, upgradeReplicaSetCheckTimeout: string>>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}") $qp $auth.query)
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

# Updates a Service Fabric application resource.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}
# operationId: Applications_Update
# --properties shape: {maximumNodes?: int, metrics?: list, minimumNodes?: int, parameters?: record, removeApplicationCapacity?: bool, typeVersion?: string, upgradePolicy?: any}
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications update" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
  --properties: any # The application resource properties for patch operations. — shape: {maximumNodes?: int, metrics?: list, minimumNodes?: int, parameters?: record, removeApplicationCapacity?: bool, typeVersion?: string, upgradePolicy?: any}
  --location: string # Azure resource location.
  --tags: record # Azure resource tags.
]: any -> record<properties: record<provisioningState: string, typeName: string, maximumNodes: int, metrics: list<record>, minimumNodes: int, parameters: record, removeApplicationCapacity: bool, typeVersion: string, upgradePolicy: record<applicationHealthPolicy: record, forceRestart: bool, rollingUpgradeMonitoringPolicy: record, upgradeReplicaSetCheckTimeout: string>>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [202]
}

# Creates or updates a Service Fabric application resource.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}
# operationId: Applications_Create
# --properties shape: {typeName?: string, maximumNodes?: int, metrics?: list, minimumNodes?: int, parameters?: record, removeApplicationCapacity?: bool, typeVersion?: string, upgradePolicy?: any}
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications create" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
  --properties: any # The application resource properties. — shape: {typeName?: string, maximumNodes?: int, metrics?: list, minimumNodes?: int, parameters?: record, removeApplicationCapacity?: bool, typeVersion?: string, upgradePolicy?: any}
  --location: string # Azure resource location.
  --tags: record # Azure resource tags.
]: any -> record<properties: record<provisioningState: string, typeName: string, maximumNodes: int, metrics: list<record>, minimumNodes: int, parameters: record, removeApplicationCapacity: bool, typeVersion: string, upgradePolicy: record<applicationHealthPolicy: record, forceRestart: bool, rollingUpgradeMonitoringPolicy: record, upgradeReplicaSetCheckTimeout: string>>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets the list of service resources created in the specified Service Fabric application resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}/services
# operationId: Services_List
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications-services list" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<nextLink: string, value: table<properties: record, etag: string, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}/services") $qp $auth.query)
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

# Deletes a Service Fabric service resource.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}/services/{serviceName}
# operationId: Services_Delete
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications-services delete" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}/services/{service_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202 204]
}

# Gets a Service Fabric service resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}/services/{serviceName}
# operationId: Services_Get
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications-services get" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
]: nothing -> record<properties: record<partitionDescription: record<partitionScheme: string>, provisioningState: string, serviceKind: string, servicePackageActivationMode: string, serviceTypeName: string, correlationScheme: list<record>, defaultMoveCost: string, placementConstraints: string, serviceLoadMetrics: list<record>, servicePlacementPolicies: list<record>>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}/services/{service_name}") $qp $auth.query)
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

# Updates a Service Fabric service resource.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}/services/{serviceName}
# operationId: Services_Update
# --properties shape: {serviceKind: "Invalid"|"Stateless"|"Stateful", correlationScheme?: list, defaultMoveCost?: "Zero"|"Low"|"Medium"|"High", placementConstraints?: string, serviceLoadMetrics?: list, servicePlacementPolicies?: list}
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications-services update" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
  --properties: any # The service resource properties for patch operations. — shape: {serviceKind: "Invalid"|"Stateless"|"Stateful", correlationScheme?: list, defaultMoveCost?: "Zero"|"Low"|"Medium"|"High", placementConstraints?: string, serviceLoadMetrics?: list, servicePlacementPolicies?: list}
  --location: string # Azure resource location.
  --tags: record # Azure resource tags.
]: any -> record<properties: record<partitionDescription: record<partitionScheme: string>, provisioningState: string, serviceKind: string, servicePackageActivationMode: string, serviceTypeName: string, correlationScheme: list<record>, defaultMoveCost: string, placementConstraints: string, serviceLoadMetrics: list<record>, servicePlacementPolicies: list<record>>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}/services/{service_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [202]
}

# Creates or updates a Service Fabric service resource.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ServiceFabric/clusters/{clusterName}/applications/{applicationName}/services/{serviceName}
# operationId: Services_Create
# --properties shape: {partitionDescription?: record, serviceKind: "Invalid"|"Stateless"|"Stateful", servicePackageActivationMode?: "SharedProcess"|"ExclusiveProcess", serviceTypeName?: string, correlationScheme?: list, defaultMoveCost?: "Zero"|"Low"|"Medium"|"High", placementConstraints?: string, serviceLoadMetrics?: list, servicePlacementPolicies?: list}
export def "subscriptions-resource-groups-providers-microsoft-service-fabric-clusters-applications-services create" [
  subscription_id: string
  resource_group_name: string
  cluster_name: string
  application_name: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string@api-version-completer # The version of the Service Fabric resource provider API. This is a required parameter and it's value must be "2019-03-01-preview" for this specification. (default: 2019-03-01-preview)
  --properties: any # The service resource properties. — shape: {partitionDescription?: record, serviceKind: "Invalid"|"Stateless"|"Stateful", servicePackageActivationMode?: "SharedProcess"|"ExclusiveProcess", serviceTypeName?: string, correlationScheme?: list, defaultMoveCost?: "Zero"|"Low"|"Medium"|"High", placementConstraints?: string, serviceLoadMetrics?: list, servicePlacementPolicies?: list}
  --location: string # Azure resource location.
  --tags: record # Azure resource tags.
]: any -> record<properties: record<partitionDescription: record<partitionScheme: string>, provisioningState: string, serviceKind: string, servicePackageActivationMode: string, serviceTypeName: string, correlationScheme: list<record>, defaultMoveCost: string, placementConstraints: string, serviceLoadMetrics: list<record>, servicePlacementPolicies: list<record>>, etag: string, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), cluster_name: (encode-path-segment $cluster_name), application_name: (encode-path-segment $application_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ServiceFabric/clusters/{cluster_name}/applications/{application_name}/services/{service_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "tags": $tags} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}
