# Auto-generated client for Microsoft Storage Sync v2019-03-01
# Source: https://api.apis.guru/v2/specs/azure.com/storagesync/2019-03-01/swagger.json
# Auth: --token flag or $env.MICROSOFT_STORAGE_SYNC_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MICROSOFT_STORAGE_SYNC_TOKEN | default "" }
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

# Completers for enum parameters
def type-completer [] { ["Microsoft.StorageSync/storageSyncServices"] }
def change-detection-mode-completer [] { ["Default" "Recursive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-storage-sync-operations list" } } | get name | first)
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

# Lists all of the available Storage Sync Rest API operations.
#
# GET /providers/Microsoft.StorageSync/operations
# operationId: Operations_List
export def "providers-microsoft-storage-sync-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.StorageSync/operations" $qp $auth.query)
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

# Check the give namespace name availability.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.StorageSync/locations/{locationName}/checkNameAvailability
# operationId: StorageSyncServices_CheckNameAvailability
export def "subscriptions-providers-microsoft-storage-sync-locations-check-name-availability sync-services" [
  subscription_id: string
  location_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  name: string # The name to check for availability
  type: string@type-completer # The resource type. Must be set to Microsoft.StorageSync/storageSyncServices
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location_name | is-empty) { error make --unspanned { msg: "path parameter 'locationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_name: (encode-path-segment $location_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.StorageSync/locations/{location_name}/checkNameAvailability") $qp $auth.query)
  let req_body = {"name": $name, "type": $type} | compact
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

# Get a StorageSyncService list by subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.StorageSync/storageSyncServices
# operationId: StorageSyncServices_ListBySubscription
export def "subscriptions-providers-microsoft-storage-sync-storage-sync-services list" [
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
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.StorageSync/storageSyncServices") $qp $auth.query)
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

# Get Operation status
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/locations/{locationName}/workflows/{workflowId}/operations/{operationId}
# operationId: OperationStatus_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-locations-workflows-operations get-status" [
  subscription_id: string
  resource_group_name: string
  location_name: string
  workflow_id: string
  operation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<endTime: string, error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, name: string, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($location_name | is-empty) { error make --unspanned { msg: "path parameter 'locationName' must be non-empty" } }
  if ($workflow_id | is-empty) { error make --unspanned { msg: "path parameter 'workflowId' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), location_name: (encode-path-segment $location_name), workflow_id: (encode-path-segment $workflow_id), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/locations/{location_name}/workflows/{workflow_id}/operations/{operation_id}") $qp $auth.query)
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

# Get a StorageSyncService list by Resource group name.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices
# operationId: StorageSyncServices_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services list" [
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
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices") $qp $auth.query)
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

# Delete a given StorageSyncService.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get a given StorageSyncService.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<storageSyncServiceStatus: int, storageSyncServiceUid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp $auth.query)
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

# Patch a given StorageSyncService.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Update
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services update" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: record # Storage Sync Service Update Properties object.
  --tags: record # The user-specified tags associated with the storage sync service.
]: any -> record<properties: record<storageSyncServiceStatus: int, storageSyncServiceUid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "tags": $tags} | compact
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

# Create a new StorageSyncService.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}
# operationId: StorageSyncServices_Create
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  location: string # Required. Gets or sets the location of the resource. This will be one of the supported and registered Azure Geo Regions (e.g. West US, East US, Southeast Asia, etc.). The geo region of a resource cannot be changed once it is created, but if an identical geo region is specified on update, the request will succeed.
  --properties: any
  --tags: record # Gets or sets a list of key value pairs that describe the resource. These tags can be used for viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key with a length no greater than 128 characters and a value with a length no greater than 256 characters.
]: any -> record<properties: record<storageSyncServiceStatus: int, storageSyncServiceUid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}") $qp $auth.query)
  let req_body = {"location": $location, "properties": $properties, "tags": $tags} | compact
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

# Get a given registered server list.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers
# operationId: RegisteredServers_ListByStorageSyncService
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers list" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers") $qp $auth.query)
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

# Delete the given registered server.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}
# operationId: RegisteredServers_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'serverId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), server_id: (encode-path-segment $server_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}") $qp $auth.query)
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

# Get a given registered server.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}
# operationId: RegisteredServers_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<agentVersion: string, clusterId: string, clusterName: string, discoveryEndpointUri: string, friendlyName: string, lastHeartBeat: string, lastOperationName: string, lastWorkflowId: string, managementEndpointUri: string, monitoringConfiguration: string, provisioningState: string, resourceLocation: string, serverCertificate: string, serverId: string, serverManagementErrorCode: int, serverOSVersion: string, serverRole: string, serviceLocation: string, storageSyncServiceUid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'serverId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), server_id: (encode-path-segment $server_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}") $qp $auth.query)
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

# Add a new registered server.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}
# operationId: RegisteredServers_Create
# --properties shape: {agentVersion?: string, clusterId?: string, clusterName?: string, friendlyName?: string, lastHeartBeat?: string, serverCertificate?: string, serverId?: string, serverOSVersion?: string, serverRole?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: any # shape: {agentVersion?: string, clusterId?: string, clusterName?: string, friendlyName?: string, lastHeartBeat?: string, serverCertificate?: string, serverId?: string, serverOSVersion?: string, serverRole?: string}
]: any -> record<properties: record<agentVersion: string, clusterId: string, clusterName: string, discoveryEndpointUri: string, friendlyName: string, lastHeartBeat: string, lastOperationName: string, lastWorkflowId: string, managementEndpointUri: string, monitoringConfiguration: string, provisioningState: string, resourceLocation: string, serverCertificate: string, serverId: string, serverManagementErrorCode: int, serverOSVersion: string, serverRole: string, serviceLocation: string, storageSyncServiceUid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'serverId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), server_id: (encode-path-segment $server_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}") $qp $auth.query)
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

# Triggers Server certificate rollover.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/registeredServers/{serverId}/triggerRollover
# operationId: RegisteredServers_triggerRollover
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-registered-servers-trigger-rollover trigger" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  server_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --server-certificate: string # Certificate Data
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($server_id | is-empty) { error make --unspanned { msg: "path parameter 'serverId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), server_id: (encode-path-segment $server_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/registeredServers/{server_id}/triggerRollover") $qp $auth.query)
  let req_body = {"serverCertificate": $server_certificate} | compact
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

# Get a SyncGroup List.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups
# operationId: SyncGroups_ListByStorageSyncService
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups list" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups") $qp $auth.query)
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

# Delete a given SyncGroup.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}
# operationId: SyncGroups_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 204]
}

# Get a given SyncGroup.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}
# operationId: SyncGroups_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<syncGroupStatus: string, uniqueId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}") $qp $auth.query)
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

# Create a new SyncGroup.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}
# operationId: SyncGroups_Create
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: record # Sync Group Create Properties object.
]: any -> record<properties: record<syncGroupStatus: string, uniqueId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}") $qp $auth.query)
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

# Get a CloudEndpoint List.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints
# operationId: CloudEndpoints_ListBySyncGroup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints list" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints") $qp $auth.query)
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

# Delete a given CloudEndpoint.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}
# operationId: CloudEndpoints_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}") $qp $auth.query)
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

# Get a given CloudEndpoint.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}
# operationId: CloudEndpoints_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<azureFileShareName: string, backupEnabled: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, partnershipId: string, provisioningState: string, storageAccountResourceId: string, storageAccountTenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}") $qp $auth.query)
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

# Create a new CloudEndpoint.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}
# operationId: CloudEndpoints_Create
# --properties shape: {azureFileShareName?: string, friendlyName?: string, storageAccountResourceId?: string, storageAccountTenantId?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: any # CloudEndpoint Properties object. — shape: {azureFileShareName?: string, friendlyName?: string, storageAccountResourceId?: string, storageAccountTenantId?: string}
]: any -> record<properties: record<azureFileShareName: string, backupEnabled: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, partnershipId: string, provisioningState: string, storageAccountResourceId: string, storageAccountTenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}") $qp $auth.query)
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

# Post Backup a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/postbackup
# operationId: CloudEndpoints_PostBackup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-post-backup create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share: string # Azure File Share.
]: any -> record<backupMetadata: record<cloudEndpointName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/postbackup") $qp $auth.query)
  let req_body = {"azureFileShare": $azure_file_share} | compact
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

# Post Restore a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/postrestore
# operationId: CloudEndpoints_PostRestore
# --restoreFileSpec item shape: {path?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-post-restore create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share-uri: string # Post Restore Azure file share uri.
  --failed-file-list: string # Post Restore Azure failed file list.
  --partition: string # Post Restore partition.
  --replica-group: string # Post Restore replica group.
  --request-id: string # Post Restore request id.
  --restore-file-spec: list # Post Restore restore file spec array. — item shape: {path?: string}
  --source-azure-file-share-uri: string # Post Restore Azure source azure file share uri.
  --status: string # Post Restore Azure status.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/postrestore") $qp $auth.query)
  let req_body = {"azureFileShareUri": $azure_file_share_uri, "failedFileList": $failed_file_list, "partition": $partition, "replicaGroup": $replica_group, "requestId": $request_id, "restoreFileSpec": $restore_file_spec, "sourceAzureFileShareUri": $source_azure_file_share_uri, "status": $status} | compact
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

# Pre Backup a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/prebackup
# operationId: CloudEndpoints_PreBackup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-prebackup create-pre-backup" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share: string # Azure File Share.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/prebackup") $qp $auth.query)
  let req_body = {"azureFileShare": $azure_file_share} | compact
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

# Pre Restore a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/prerestore
# operationId: CloudEndpoints_PreRestore
# --restoreFileSpec item shape: {path?: string}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-prerestore create-pre-restore" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --azure-file-share-uri: string # Pre Restore Azure file share uri.
  --backup-metadata-property-bag: string # Pre Restore backup metadata property bag.
  --partition: string # Pre Restore partition.
  --pause-wait-for-sync-drain-time-period-in-seconds: int # Pre Restore pause wait for sync drain time period in seconds.
  --replica-group: string # Pre Restore replica group.
  --request-id: string # Pre Restore request id.
  --restore-file-spec: list # Pre Restore restore file spec array. — item shape: {path?: string}
  --source-azure-file-share-uri: string # Pre Restore Azure source azure file share uri.
  --status: string # Pre Restore Azure status.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/prerestore") $qp $auth.query)
  let req_body = {"azureFileShareUri": $azure_file_share_uri, "backupMetadataPropertyBag": $backup_metadata_property_bag, "partition": $partition, "pauseWaitForSyncDrainTimePeriodInSeconds": $pause_wait_for_sync_drain_time_period_in_seconds, "replicaGroup": $replica_group, "requestId": $request_id, "restoreFileSpec": $restore_file_spec, "sourceAzureFileShareUri": $source_azure_file_share_uri, "status": $status} | compact
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

# Restore Heartbeat a given CloudEndpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/restoreheartbeat
# operationId: CloudEndpoints_restoreheartbeat
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-restoreheartbeat create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/restoreheartbeat") $qp $auth.query)
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

# Triggers detection of changes performed on Azure File share connected to the specified Azure File Sync Cloud Endpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/cloudEndpoints/{cloudEndpointName}/triggerChangeDetection
# operationId: CloudEndpoints_TriggerChangeDetection
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-cloud-endpoints-trigger-change-detection trigger" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  cloud_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --change-detection-mode: string@change-detection-mode-completer # Change Detection Mode. Applies to a directory specified in directoryPath parameter.
  --directory-path: string # Relative path to a directory Azure File share for which change detection is to be performed.
  --paths: list<string> # Array of relative paths on the Azure File share to be included in the change detection. Can be files and directories.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($cloud_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'cloudEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), cloud_endpoint_name: (encode-path-segment $cloud_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/cloudEndpoints/{cloud_endpoint_name}/triggerChangeDetection") $qp $auth.query)
  let req_body = {"changeDetectionMode": $change_detection_mode, "directoryPath": $directory_path, "paths": $paths} | compact
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

# Get a ServerEndpoint list.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints
# operationId: ServerEndpoints_ListBySyncGroup
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints list" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints") $qp $auth.query)
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

# Delete a given ServerEndpoint.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Delete
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints delete" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($server_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'serverEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), server_endpoint_name: (encode-path-segment $server_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 202]
}

# Get a ServerEndpoint.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<cloudTiering: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, offlineDataTransfer: string, offlineDataTransferShareName: string, offlineDataTransferStorageAccountResourceId: string, offlineDataTransferStorageAccountTenantId: string, provisioningState: string, serverLocalPath: string, serverResourceId: string, syncStatus: record<combinedHealth: string, downloadActivity: record, downloadHealth: string, downloadStatus: record, lastUpdatedTimestamp: string, offlineDataTransferStatus: string, syncActivity: string, totalPersistentFilesNotSyncingCount: int, uploadActivity: record, uploadHealth: string, uploadStatus: record>, tierFilesOlderThanDays: int, volumeFreeSpacePercent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($server_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'serverEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), server_endpoint_name: (encode-path-segment $server_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp $auth.query)
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

# Patch a given ServerEndpoint.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Update
# --properties shape: {cloudTiering?: "on"|"off", offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints update" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: record # ServerEndpoint Update Properties object. — shape: {cloudTiering?: "on"|"off", offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
]: any -> record<properties: record<cloudTiering: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, offlineDataTransfer: string, offlineDataTransferShareName: string, offlineDataTransferStorageAccountResourceId: string, offlineDataTransferStorageAccountTenantId: string, provisioningState: string, serverLocalPath: string, serverResourceId: string, syncStatus: record<combinedHealth: string, downloadActivity: record, downloadHealth: string, downloadStatus: record, lastUpdatedTimestamp: string, offlineDataTransferStatus: string, syncActivity: string, totalPersistentFilesNotSyncingCount: int, uploadActivity: record, uploadHealth: string, uploadStatus: record>, tierFilesOlderThanDays: int, volumeFreeSpacePercent: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($server_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'serverEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), server_endpoint_name: (encode-path-segment $server_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp $auth.query)
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Create a new ServerEndpoint.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}
# operationId: ServerEndpoints_Create
# --properties shape: {cloudTiering?: "on"|"off", friendlyName?: string, offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, serverLocalPath?: string, serverResourceId?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --properties: any # ServerEndpoint Properties object. — shape: {cloudTiering?: "on"|"off", friendlyName?: string, offlineDataTransfer?: "on"|"off", offlineDataTransferShareName?: string, serverLocalPath?: string, serverResourceId?: string, tierFilesOlderThanDays?: int, volumeFreeSpacePercent?: int}
]: any -> record<properties: record<cloudTiering: string, friendlyName: string, lastOperationName: string, lastWorkflowId: string, offlineDataTransfer: string, offlineDataTransferShareName: string, offlineDataTransferStorageAccountResourceId: string, offlineDataTransferStorageAccountTenantId: string, provisioningState: string, serverLocalPath: string, serverResourceId: string, syncStatus: record<combinedHealth: string, downloadActivity: record, downloadHealth: string, downloadStatus: record, lastUpdatedTimestamp: string, offlineDataTransferStatus: string, syncActivity: string, totalPersistentFilesNotSyncingCount: int, uploadActivity: record, uploadHealth: string, uploadStatus: record>, tierFilesOlderThanDays: int, volumeFreeSpacePercent: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($server_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'serverEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), server_endpoint_name: (encode-path-segment $server_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}") $qp $auth.query)
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

# Recall a server endpoint.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/syncGroups/{syncGroupName}/serverEndpoints/{serverEndpointName}/recallAction
# operationId: ServerEndpoints_recallAction
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-sync-groups-server-endpoints-recall-action create" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  sync_group_name: string
  server_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
  --pattern: string # Pattern of the files.
  --recall-path: string # Recall path.
]: any -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($sync_group_name | is-empty) { error make --unspanned { msg: "path parameter 'syncGroupName' must be non-empty" } }
  if ($server_endpoint_name | is-empty) { error make --unspanned { msg: "path parameter 'serverEndpointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), sync_group_name: (encode-path-segment $sync_group_name), server_endpoint_name: (encode-path-segment $server_endpoint_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/syncGroups/{sync_group_name}/serverEndpoints/{server_endpoint_name}/recallAction") $qp $auth.query)
  let req_body = {"pattern": $pattern, "recallPath": $recall_path} | compact
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

# Get a Workflow List
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/workflows
# operationId: Workflows_ListByStorageSyncService
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-workflows list" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/workflows") $qp $auth.query)
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

# Get Workflows resource
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/workflows/{workflowId}
# operationId: Workflows_Get
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-workflows get" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<properties: record<lastOperationId: string, lastStepName: string, operation: string, status: string, steps: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($workflow_id | is-empty) { error make --unspanned { msg: "path parameter 'workflowId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), workflow_id: (encode-path-segment $workflow_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/workflows/{workflow_id}") $qp $auth.query)
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

# Abort the given workflow.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.StorageSync/storageSyncServices/{storageSyncServiceName}/workflows/{workflowId}/abort
# operationId: Workflows_Abort
export def "subscriptions-resource-groups-providers-microsoft-storage-sync-storage-sync-services-workflows-abort abort" [
  subscription_id: string
  resource_group_name: string
  storage_sync_service_name: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use for this operation.
]: nothing -> record<error: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>, innererror: record<code: string, details: record<code: string, message: string, target: string>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($storage_sync_service_name | is-empty) { error make --unspanned { msg: "path parameter 'storageSyncServiceName' must be non-empty" } }
  if ($workflow_id | is-empty) { error make --unspanned { msg: "path parameter 'workflowId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), storage_sync_service_name: (encode-path-segment $storage_sync_service_name), workflow_id: (encode-path-segment $workflow_id)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.StorageSync/storageSyncServices/{storage_sync_service_name}/workflows/{workflow_id}/abort") $qp $auth.query)
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
