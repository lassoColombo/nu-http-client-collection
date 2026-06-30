# Auto-generated client for ContainerRegistryManagementClient v2019-06-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/containerregistry-containerregistry_build/2019-06-01-preview/swagger.json
# Auth: --token flag or $env.CONTAINERREGISTRYMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CONTAINERREGISTRYMANAGEMENTCLIENT_TOKEN | default "" }
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-container-registry-registries-list-build-source-upload-url get" } } | get name | first)
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

# Get the upload location for the user to be able to upload the source.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/listBuildSourceUploadUrl
# operationId: Registries_GetBuildSourceUploadUrl
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-list-build-source-upload-url get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<relativePath: string, uploadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/listBuildSourceUploadUrl") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Gets all the runs for a registry.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs
# operationId: Runs_List
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs list" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --filter: string # The runs filter to apply on the operation. Arithmetic operators are not supported. The allowed string function is 'contains'. All logical operators except 'Not', 'Has', 'All' are allowed.
  --top: int # $top is supported for get list of runs, which limits the maximum number of runs to return. (format: int32)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "$filter": $filter, "$top": $top} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the detailed information for a given run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}
# operationId: Runs_Get
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<properties: record<agentConfiguration: record<cpu: int>, createTime: string, customRegistries: list<string>, finishTime: string, imageUpdateTrigger: record<id: string, images: list, timestamp: string>, isArchiveEnabled: bool, lastUpdatedTime: string, outputImages: list<record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, runErrorMessage: string, runId: string, runType: string, sourceRegistryAuth: string, sourceTrigger: record<branchName: string, commitId: string, eventType: string, id: string, providerType: string, pullRequestId: string, repositoryUrl: string>, startTime: string, status: string, task: string, timerTrigger: record<scheduleOccurrence: string, timerTriggerName: string>, updateTriggerToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}") $qp $auth.query)
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

# Patch the run properties.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}
# operationId: Runs_Update
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs update" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --is-archive-enabled: oneof<nothing, bool> # The value that indicates whether archiving is enabled or not.
]: any -> record<properties: record<agentConfiguration: record<cpu: int>, createTime: string, customRegistries: list<string>, finishTime: string, imageUpdateTrigger: record<id: string, images: list, timestamp: string>, isArchiveEnabled: bool, lastUpdatedTime: string, outputImages: list<record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, runErrorMessage: string, runId: string, runType: string, sourceRegistryAuth: string, sourceTrigger: record<branchName: string, commitId: string, eventType: string, id: string, providerType: string, pullRequestId: string, repositoryUrl: string>, startTime: string, status: string, task: string, timerTrigger: record<scheduleOccurrence: string, timerTriggerName: string>, updateTriggerToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}") $qp $auth.query)
  let req_body = {"isArchiveEnabled": $is_archive_enabled} | compact
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Cancel an existing run.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}/cancel
# operationId: Runs_Cancel
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs-cancel cancel" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}/cancel") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 202]
}

# Gets a link to download the run logs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/runs/{runId}/listLogSasUrl
# operationId: Runs_GetLogSasUrl
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-runs-list-log-sas-url get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<logLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($run_id | is-empty) { error make --unspanned { msg: "path parameter 'runId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), run_id: (encode-path-segment $run_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/runs/{run_id}/listLogSasUrl") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Schedules a new run based on the request parameters and add it to the run queue.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/scheduleRun
# Discriminator (request): type
# operationId: Registries_ScheduleRun
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-schedule-run create" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --is-archive-enabled: oneof<nothing, bool> # The value that indicates whether archiving is enabled for the run or not. (default: false)
  type: string # The type of the run request.
]: any -> record<properties: record<agentConfiguration: record<cpu: int>, createTime: string, customRegistries: list<string>, finishTime: string, imageUpdateTrigger: record<id: string, images: list, timestamp: string>, isArchiveEnabled: bool, lastUpdatedTime: string, outputImages: list<record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, runErrorMessage: string, runId: string, runType: string, sourceRegistryAuth: string, sourceTrigger: record<branchName: string, commitId: string, eventType: string, id: string, providerType: string, pullRequestId: string, repositoryUrl: string>, startTime: string, status: string, task: string, timerTrigger: record<scheduleOccurrence: string, timerTriggerName: string>, updateTriggerToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/scheduleRun") $qp $auth.query)
  let req_body = {"isArchiveEnabled": $is_archive_enabled, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Lists all the task runs for a specified container registry.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns
# operationId: TaskRuns_List
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs list" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns") $qp $auth.query)
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

# Deletes a specified task run resource.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Delete
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs delete" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_run_name | is-empty) { error make --unspanned { msg: "path parameter 'taskRunName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets the detailed information for a given task run.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Get
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<forceUpdateTag: string, provisioningState: string, runRequest: record<isArchiveEnabled: bool, type: string>, runResult: record<properties: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_run_name | is-empty) { error make --unspanned { msg: "path parameter 'taskRunName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp $auth.query)
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

# Updates a task run with the specified parameters.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Update
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {forceUpdateTag?: string, runRequest?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs update" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties of a task run update parameters. — shape: {forceUpdateTag?: string, runRequest?: record}
  --tags: record # The ARM resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<forceUpdateTag: string, provisioningState: string, runRequest: record<isArchiveEnabled: bool, type: string>, runResult: record<properties: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_run_name | is-empty) { error make --unspanned { msg: "path parameter 'taskRunName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp $auth.query)
  let req_body = {"identity": $identity, "properties": $properties, "tags": $tags} | compact
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Creates a task run for a container registry with the specified parameters.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/taskRuns/{taskRunName}
# operationId: TaskRuns_Create
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {forceUpdateTag?: string, runRequest?: record, runResult?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-task-runs create" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_run_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties of task run. — shape: {forceUpdateTag?: string, runRequest?: record, runResult?: record}
  location: string # The location of the resource. This cannot be changed after the resource is created.
  --tags: record # The tags of the resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<forceUpdateTag: string, provisioningState: string, runRequest: record<isArchiveEnabled: bool, type: string>, runResult: record<properties: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_run_name | is-empty) { error make --unspanned { msg: "path parameter 'taskRunName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_run_name: (encode-path-segment $task_run_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/taskRuns/{task_run_name}") $qp $auth.query)
  let req_body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Lists all the tasks for a specified container registry.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks
# operationId: Tasks_List
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks list" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<nextLink: string, value: table<identity: record, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks") $qp $auth.query)
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

# Deletes a specified task.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Delete
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks delete" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_name | is-empty) { error make --unspanned { msg: "path parameter 'taskName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Get the properties of a specified task.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Get
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_name | is-empty) { error make --unspanned { msg: "path parameter 'taskName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp $auth.query)
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

# Updates a task with the specified parameters.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Update
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {agentConfiguration?: record, credentials?: record, platform?: record, status?: "Disabled"|"Enabled", step?: record, timeout?: int, trigger?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks update" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties for updating a task. — shape: {agentConfiguration?: record, credentials?: record, platform?: record, status?: "Disabled"|"Enabled", step?: record, timeout?: int, trigger?: record}
  --tags: record # The ARM resource tags.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_name | is-empty) { error make --unspanned { msg: "path parameter 'taskName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp $auth.query)
  let req_body = {"identity": $identity, "properties": $properties, "tags": $tags} | compact
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Creates a task for a container registry with the specified parameters.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}
# operationId: Tasks_Create
# --identity shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
# --properties shape: {agentConfiguration?: record, credentials?: record, platform: record, status?: "Disabled"|"Enabled", step: record, timeout?: int, trigger?: record}
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks create" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
  --identity: record # Managed identity for the resource. — shape: {principalId?: string, tenantId?: string, type?: "SystemAssigned"|"UserAssigned"|"SystemAssigned, UserAssigned"|"None", userAssignedIdentities?: record}
  --properties: record # The properties of a task. — shape: {agentConfiguration?: record, credentials?: record, platform: record, status?: "Disabled"|"Enabled", step: record, timeout?: int, trigger?: record}
  location: string # The location of the resource. This cannot be changed after the resource is created.
  --tags: record # The tags of the resource.
]: any -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_name | is-empty) { error make --unspanned { msg: "path parameter 'taskName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}") $qp $auth.query)
  let req_body = {"identity": $identity, "properties": $properties, "location": $location, "tags": $tags} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Returns a task with extended information that includes all secrets.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/{registryName}/tasks/{taskName}/listDetails
# operationId: Tasks_GetDetails
export def "subscriptions-resource-groups-providers-microsoft-container-registry-registries-tasks-list-details get" [
  subscription_id: string
  resource_group_name: string
  registry_name: string
  task_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The client API version.
]: nothing -> record<identity: record<principalId: string, tenantId: string, type: string, userAssignedIdentities: record>, properties: record<agentConfiguration: record<cpu: int>, creationDate: string, credentials: record<customRegistries: record, sourceRegistry: record>, platform: record<architecture: string, os: string, variant: string>, provisioningState: string, status: string, step: record<baseImageDependencies: list, contextAccessToken: string, contextPath: string, type: string>, timeout: int, trigger: record<baseImageTrigger: record, sourceTriggers: list, timerTriggers: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registryName' must be non-empty" } }
  if ($task_name | is-empty) { error make --unspanned { msg: "path parameter 'taskName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), registry_name: (encode-path-segment $registry_name), task_name: (encode-path-segment $task_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ContainerRegistry/registries/{registry_name}/tasks/{task_name}/listDetails") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}
