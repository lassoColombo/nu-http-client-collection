# Auto-generated client for BatchAI v2018-05-01
# Source: https://api.apis.guru/v2/specs/azure.com/batchai-BatchAI/2018-05-01/swagger.json
# Auth: --token flag or $env.BATCHAI_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BATCHAI_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-batch-ai-operations list" } } | get name | first)
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

# Lists available operations for the Microsoft.BatchAI provider.
#
# GET /providers/Microsoft.BatchAI/operations
# operationId: Operations_List
export def "providers-microsoft-batch-ai-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.BatchAI/operations" $qp $auth.query)
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

# Gets the current usage information as well as limits for Batch AI resources for given subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.BatchAI/locations/{location}/usages
# operationId: Usages_List
export def "subscriptions-providers-microsoft-batch-ai-locations-usages list" [
  subscription_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<currentValue: int, limit: int, name: record, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location: (encode-path-segment $location)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.BatchAI/locations/{location}/usages") $qp $auth.query)
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

# Gets a list of Workspaces associated with the given subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.BatchAI/workspaces
# operationId: Workspaces_List
export def "subscriptions-providers-microsoft-batch-ai-workspaces list" [
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
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.BatchAI/workspaces") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxresults": $maxresults, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of Workspaces within the specified resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces
# operationId: Workspaces_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces list" [
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
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxresults": $maxresults, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a Workspace.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces delete" [
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
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp $auth.query)
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

# Gets information about a Workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces get" [
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
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp $auth.query)
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

# Updates properties of a Workspace.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Update
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces update" [
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
  --api-version: string # Specifies the version of API used for this request.
  --tags: record # The user specified tags associated with the Workspace.
]: any -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp $auth.query)
  let req_body = {"tags": $tags} | compact
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

# Creates a Workspace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}
# operationId: Workspaces_Create
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces create" [
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
  --api-version: string # Specifies the version of API used for this request.
  location: string # The region in which to create the Workspace.
  --tags: record # The user specified tags associated with the Workspace.
]: any -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}") $qp $auth.query)
  let req_body = {"location": $location, "tags": $tags} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Gets information about Clusters associated with the given Workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters
# operationId: Clusters_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters list" [
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
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxresults": $maxresults, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a Cluster.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
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
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp $auth.query)
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

# Gets information about a Cluster.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
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
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, creationTime: string, currentNodeCount: int, errors: list<record>, nodeSetup: record<mountVolumes: record, performanceCountersSettings: record, setupTask: record>, nodeStateCounts: record<idleNodeCount: int, leavingNodeCount: int, preparingNodeCount: int, runningNodeCount: int, unusableNodeCount: int>, provisioningState: string, provisioningStateTransitionTime: string, scaleSettings: record<autoScale: record, manual: record>, subnet: record<id: string>, userAccountSettings: record<adminUserName: string, adminUserPassword: string, adminUserSshPublicKey: string>, virtualMachineConfiguration: record<imageReference: record>, vmPriority: string, vmSize: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp $auth.query)
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

# Updates properties of a Cluster.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Update
# --properties shape: {scaleSettings?: any}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters update" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
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
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a Cluster that need to be updated. — shape: {scaleSettings?: any}
]: any -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, creationTime: string, currentNodeCount: int, errors: list<record>, nodeSetup: record<mountVolumes: record, performanceCountersSettings: record, setupTask: record>, nodeStateCounts: record<idleNodeCount: int, leavingNodeCount: int, preparingNodeCount: int, runningNodeCount: int, unusableNodeCount: int>, provisioningState: string, provisioningStateTransitionTime: string, scaleSettings: record<autoScale: record, manual: record>, subnet: record<id: string>, userAccountSettings: record<adminUserName: string, adminUserPassword: string, adminUserSshPublicKey: string>, virtualMachineConfiguration: record<imageReference: record>, vmPriority: string, vmSize: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp $auth.query)
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

# Creates a Cluster in the given Workspace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}
# operationId: Clusters_Create
# --properties shape: {nodeSetup?: any, scaleSettings?: any, subnet?: any, userAccountSettings: any, virtualMachineConfiguration?: any, vmPriority?: "dedicated"|"lowpriority", vmSize: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
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
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a Cluster. — shape: {nodeSetup?: any, scaleSettings?: any, subnet?: any, userAccountSettings: any, virtualMachineConfiguration?: any, vmPriority?: "dedicated"|"lowpriority", vmSize: string}
]: any -> record<properties: record<allocationState: string, allocationStateTransitionTime: string, creationTime: string, currentNodeCount: int, errors: list<record>, nodeSetup: record<mountVolumes: record, performanceCountersSettings: record, setupTask: record>, nodeStateCounts: record<idleNodeCount: int, leavingNodeCount: int, preparingNodeCount: int, runningNodeCount: int, unusableNodeCount: int>, provisioningState: string, provisioningStateTransitionTime: string, scaleSettings: record<autoScale: record, manual: record>, subnet: record<id: string>, userAccountSettings: record<adminUserName: string, adminUserPassword: string, adminUserSshPublicKey: string>, virtualMachineConfiguration: record<imageReference: record>, vmPriority: string, vmSize: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}") $qp $auth.query)
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Get the IP address, port of all the compute nodes in the Cluster.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/clusters/{clusterName}/listRemoteLoginInformation
# operationId: Clusters_ListRemoteLoginInformation
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-clusters-list-remote-login-information list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
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
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<ipAddress: string, nodeId: string, port: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($cluster_name | is-empty) { error make --unspanned { msg: "path parameter 'clusterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), cluster_name: (encode-path-segment $cluster_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/clusters/{cluster_name}/listRemoteLoginInformation") $qp $auth.query)
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

# Gets a list of Experiments within the specified Workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments
# operationId: Experiments_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments list" [
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
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxresults": $maxresults, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an Experiment.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}") $qp $auth.query)
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

# Gets information about an Experiment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}") $qp $auth.query)
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

# Creates an Experiment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}
# operationId: Experiments_Create
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, provisioningState: string, provisioningStateTransitionTime: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 202]
}

# Gets a list of Jobs within the specified Experiment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs
# operationId: Jobs_ListByExperiment
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxresults": $maxresults, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a Job.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}
# operationId: Jobs_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}") $qp $auth.query)
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

# Gets information about a Job.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}
# operationId: Jobs_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<caffe2Settings: record<commandLineArgs: string, pythonInterpreterPath: string, pythonScriptFilePath: string>, caffeSettings: record<commandLineArgs: string, configFilePath: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, chainerSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, cluster: record<id: string>, cntkSettings: record<commandLineArgs: string, configFilePath: string, languageType: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, constraints: record<maxWallClockTime: string>, containerSettings: record<imageSourceRegistry: record, shmSize: string>, creationTime: string, customMpiSettings: record<commandLine: string, processCount: int>, customToolkitSettings: record<commandLine: string>, environmentVariables: list<record>, executionInfo: record<endTime: string, errors: list, exitCode: int, startTime: string>, executionState: string, executionStateTransitionTime: string, horovodSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, inputDirectories: list<record>, jobOutputDirectoryPathSegment: string, jobPreparation: record<commandLine: string>, mountVolumes: record<azureBlobFileSystems: list, azureFileShares: list, fileServers: list, unmanagedFileSystems: list>, nodeCount: int, outputDirectories: list<record>, provisioningState: string, provisioningStateTransitionTime: string, pyTorchSettings: record<commandLineArgs: string, communicationBackend: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, schedulingPriority: string, secrets: list<record>, stdOutErrPathPrefix: string, tensorFlowSettings: record<masterCommandLineArgs: string, parameterServerCommandLineArgs: string, parameterServerCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string, workerCommandLineArgs: string, workerCount: int>, toolType: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}") $qp $auth.query)
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

# Creates a Job in the given Experiment.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}
# operationId: Jobs_Create
# --properties shape: {caffe2Settings?: any, caffeSettings?: any, chainerSettings?: any, cluster: any, cntkSettings?: any, constraints?: any, containerSettings?: any, customMpiSettings?: any, customToolkitSettings?: any, environmentVariables?: list, horovodSettings?: any, inputDirectories?: list, jobPreparation?: any, mountVolumes?: any, nodeCount: int, outputDirectories?: list, pyTorchSettings?: any, schedulingPriority?: "low"|"normal"|"high", secrets?: list, stdOutErrPathPrefix: string, tensorFlowSettings?: any}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a Batch AI Job. — shape: {caffe2Settings?: any, caffeSettings?: any, chainerSettings?: any, cluster: any, cntkSettings?: any, constraints?: any, containerSettings?: any, customMpiSettings?: any, customToolkitSettings?: any, environmentVariables?: list, horovodSettings?: any, inputDirectories?: list, jobPreparation?: any, mountVolumes?: any, nodeCount: int, outputDirectories?: list, pyTorchSettings?: any, schedulingPriority?: "low"|"normal"|"high", secrets?: list, stdOutErrPathPrefix: string, tensorFlowSettings?: any}
]: any -> record<properties: record<caffe2Settings: record<commandLineArgs: string, pythonInterpreterPath: string, pythonScriptFilePath: string>, caffeSettings: record<commandLineArgs: string, configFilePath: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, chainerSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, cluster: record<id: string>, cntkSettings: record<commandLineArgs: string, configFilePath: string, languageType: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, constraints: record<maxWallClockTime: string>, containerSettings: record<imageSourceRegistry: record, shmSize: string>, creationTime: string, customMpiSettings: record<commandLine: string, processCount: int>, customToolkitSettings: record<commandLine: string>, environmentVariables: list<record>, executionInfo: record<endTime: string, errors: list, exitCode: int, startTime: string>, executionState: string, executionStateTransitionTime: string, horovodSettings: record<commandLineArgs: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, inputDirectories: list<record>, jobOutputDirectoryPathSegment: string, jobPreparation: record<commandLine: string>, mountVolumes: record<azureBlobFileSystems: list, azureFileShares: list, fileServers: list, unmanagedFileSystems: list>, nodeCount: int, outputDirectories: list<record>, provisioningState: string, provisioningStateTransitionTime: string, pyTorchSettings: record<commandLineArgs: string, communicationBackend: string, processCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string>, schedulingPriority: string, secrets: list<record>, stdOutErrPathPrefix: string, tensorFlowSettings: record<masterCommandLineArgs: string, parameterServerCommandLineArgs: string, parameterServerCount: int, pythonInterpreterPath: string, pythonScriptFilePath: string, workerCommandLineArgs: string, workerCount: int>, toolType: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}") $qp $auth.query)
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# List all directories and files inside the given directory of the Job's output directory (if the output directory is on Azure File Share or Azure Storage Container).
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}/listOutputFiles
# operationId: Jobs_ListOutputFiles
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs-list-output-files list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --outputdirectoryid: string # Id of the job output directory. This is the OutputDirectory-->id parameter that is given by the user during Create Job.
  --directory: string # The path to the directory. (default: .)
  --linkexpiryinminutes: int # The number of minutes after which the download link will expire. (format: int32, default: 60)
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<downloadUrl: string, fileType: string, name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "outputdirectoryid" $outputdirectoryid "scalar") (serialize-qp "directory" $directory "scalar") (serialize-qp "linkexpiryinminutes" $linkexpiryinminutes "scalar") (serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}/listOutputFiles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"outputdirectoryid": $outputdirectoryid, "directory": $directory, "linkexpiryinminutes": $linkexpiryinminutes, "maxresults": $maxresults, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Gets a list of currently existing nodes which were used for the Job execution. The returned information contains the node ID, its public IP and SSH port.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}/listRemoteLoginInformation
# operationId: Jobs_ListRemoteLoginInformation
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs-list-remote-login-information list" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<ipAddress: string, nodeId: string, port: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}/listRemoteLoginInformation") $qp $auth.query)
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

# Terminates a job.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/experiments/{experimentName}/jobs/{jobName}/terminate
# operationId: Jobs_Terminate
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-experiments-jobs-terminate create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  experiment_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($experiment_name | is-empty) { error make --unspanned { msg: "path parameter 'experimentName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), experiment_name: (encode-path-segment $experiment_name), job_name: (encode-path-segment $job_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/experiments/{experiment_name}/jobs/{job_name}/terminate") $qp $auth.query)
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

# Gets a list of File Servers associated with the specified workspace.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers
# operationId: FileServers_ListByWorkspace
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers list" [
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
  --maxresults: int # The maximum number of items to return in the response. A maximum of 1000 files can be returned. (format: int32, default: 1000)
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  let qp = [(serialize-qp "maxresults" $maxresults "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxresults": $maxresults, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a File Server.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers/{fileServerName}
# operationId: FileServers_Delete
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers delete" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  file_server_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($file_server_name | is-empty) { error make --unspanned { msg: "path parameter 'fileServerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), file_server_name: (encode-path-segment $file_server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers/{file_server_name}") $qp $auth.query)
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

# Gets information about a File Server.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers/{fileServerName}
# operationId: FileServers_Get
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers get" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  file_server_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
]: nothing -> record<properties: record<creationTime: string, dataDisks: record<cachingType: string, diskCount: int, diskSizeInGB: int, storageAccountType: string>, mountSettings: record<fileServerInternalIP: string, fileServerPublicIP: string, mountPoint: string>, provisioningState: string, provisioningStateTransitionTime: string, sshConfiguration: record<publicIPsToAllow: list, userAccountSettings: record>, subnet: record<id: string>, vmSize: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($file_server_name | is-empty) { error make --unspanned { msg: "path parameter 'fileServerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), file_server_name: (encode-path-segment $file_server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers/{file_server_name}") $qp $auth.query)
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

# Creates a File Server in the given workspace.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.BatchAI/workspaces/{workspaceName}/fileServers/{fileServerName}
# operationId: FileServers_Create
# --properties shape: {dataDisks: any, sshConfiguration: any, subnet?: any, vmSize: string}
export def "subscriptions-resource-groups-providers-microsoft-batch-ai-workspaces-file-servers create" [
  subscription_id: string
  resource_group_name: string
  workspace_name: string
  file_server_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Specifies the version of API used for this request.
  --properties: any # The properties of a file server. — shape: {dataDisks: any, sshConfiguration: any, subnet?: any, vmSize: string}
]: any -> record<properties: record<creationTime: string, dataDisks: record<cachingType: string, diskCount: int, diskSizeInGB: int, storageAccountType: string>, mountSettings: record<fileServerInternalIP: string, fileServerPublicIP: string, mountPoint: string>, provisioningState: string, provisioningStateTransitionTime: string, sshConfiguration: record<publicIPsToAllow: list, userAccountSettings: record>, subnet: record<id: string>, vmSize: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($workspace_name | is-empty) { error make --unspanned { msg: "path parameter 'workspaceName' must be non-empty" } }
  if ($file_server_name | is-empty) { error make --unspanned { msg: "path parameter 'fileServerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), workspace_name: (encode-path-segment $workspace_name), file_server_name: (encode-path-segment $file_server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.BatchAI/workspaces/{workspace_name}/fileServers/{file_server_name}") $qp $auth.query)
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}
