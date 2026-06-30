# Auto-generated client for CustomerInsightsManagementClient v2017-04-26
# Source: https://api.apis.guru/v2/specs/azure.com/customer-insights/2017-04-26/swagger.json
# Auth: --token flag or $env.CUSTOMERINSIGHTSMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CUSTOMERINSIGHTSMANAGEMENTCLIENT_TOKEN | default "" }
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
def status-completer [] { ["Active" "Deleted" "Discovering" "Evaluating" "EvaluatingFailed" "Failed" "Featuring" "FeaturingFailed" "HumanIntervention" "New" "PendingDiscovering" "PendingFeaturing" "PendingModelConfirmation" "PendingTraining" "Provisioning" "ProvisioningFailed" "Training" "TrainingFailed"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-customer-insights-operations list" } } | get name | first)
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

# Lists all of the available Customer Insights REST API operations.
#
# GET /providers/Microsoft.CustomerInsights/operations
# operationId: Operations_List
export def "providers-microsoft-customer-insights-operations list" [
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
  let full_url = (build-url $base "/providers/Microsoft.CustomerInsights/operations" $qp $auth.query)
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

# Gets all hubs in the specified subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.CustomerInsights/hubs
# operationId: Hubs_List
export def "subscriptions-providers-microsoft-customer-insights-hubs list" [
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.CustomerInsights/hubs") $qp $auth.query)
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

# Gets all the hubs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs
# operationId: Hubs_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs list" [
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, location: string, name: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs") $qp $auth.query)
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

# Deletes the specified hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}") $qp $auth.query)
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

# Gets information about the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}") $qp $auth.query)
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

# Updates a Hub.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_Update
# --properties shape: {hubBillingInfo?: any, tenantFeatures?: int}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --properties: any # Properties of hub. — shape: {hubBillingInfo?: any, tenantFeatures?: int}
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}") $qp $auth.query)
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a hub, or updates an existing hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}
# operationId: Hubs_CreateOrUpdate
# --properties shape: {hubBillingInfo?: any, tenantFeatures?: int}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --properties: any # Properties of hub. — shape: {hubBillingInfo?: any, tenantFeatures?: int}
  --location: string # Resource location.
  --tags: record # Resource tags.
]: any -> record<properties: record<apiEndpoint: string, hubBillingInfo: record<maxUnits: int, minUnits: int, skuName: string>, provisioningState: string, tenantFeatures: int, webEndpoint: string>, id: string, location: string, name: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}") $qp $auth.query)
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Gets all the authorization policies in a specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies
# operationId: AuthorizationPolicies_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/authorizationPolicies") $qp $auth.query)
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

# Gets an authorization policy in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}
# operationId: AuthorizationPolicies_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
]: nothing -> record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($authorization_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), authorization_policy_name: (encode-path-segment $authorization_policy_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/authorizationPolicies/{authorization_policy_name}") $qp $auth.query)
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

# Creates an authorization policy or updates an existing authorization policy.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}
# operationId: AuthorizationPolicies_CreateOrUpdate
# --properties shape: {permissions: list<string>, primaryKey?: string, secondaryKey?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
  --properties: any # The authorization policy. — shape: {permissions: list<string>, primaryKey?: string, secondaryKey?: string}
]: any -> record<properties: record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($authorization_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), authorization_policy_name: (encode-path-segment $authorization_policy_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/authorizationPolicies/{authorization_policy_name}") $qp $auth.query)
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Regenerates the primary policy key of the specified authorization policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regeneratePrimaryKey
# operationId: AuthorizationPolicies_RegeneratePrimaryKey
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies-regenerate-primary-key create" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
]: nothing -> record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($authorization_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), authorization_policy_name: (encode-path-segment $authorization_policy_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/authorizationPolicies/{authorization_policy_name}/regeneratePrimaryKey") $qp $auth.query)
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

# Regenerates the secondary policy key of the specified authorization policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/authorizationPolicies/{authorizationPolicyName}/regenerateSecondaryKey
# operationId: AuthorizationPolicies_RegenerateSecondaryKey
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-authorization-policies-regenerate-secondary-key create" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  authorization_policy_name: string
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
]: nothing -> record<permissions: list<string>, policyName: string, primaryKey: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($authorization_policy_name | is-empty) { error make --unspanned { msg: "path parameter 'authorizationPolicyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), authorization_policy_name: (encode-path-segment $authorization_policy_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/authorizationPolicies/{authorization_policy_name}/regenerateSecondaryKey") $qp $auth.query)
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

# Gets all the connectors in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors
# operationId: Connectors_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors") $qp $auth.query)
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

# Deletes a connector in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# operationId: Connectors_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($connector_name | is-empty) { error make --unspanned { msg: "path parameter 'connectorName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), connector_name: (encode-path-segment $connector_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors/{connector_name}") $qp $auth.query)
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

# Gets a connector in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# operationId: Connectors_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
]: nothing -> record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($connector_name | is-empty) { error make --unspanned { msg: "path parameter 'connectorName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), connector_name: (encode-path-segment $connector_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors/{connector_name}") $qp $auth.query)
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

# Creates a connector or updates an existing connector in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}
# operationId: Connectors_CreateOrUpdate
# --properties shape: {connectorName?: string, connectorProperties: record, connectorType: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, isInternal?: bool}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
  --properties: any # Properties of connector. — shape: {connectorName?: string, connectorProperties: record, connectorType: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, isInternal?: bool}
]: any -> record<properties: record<connectorId: int, connectorName: string, connectorProperties: record, connectorType: string, created: string, description: string, displayName: string, isInternal: bool, lastModified: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($connector_name | is-empty) { error make --unspanned { msg: "path parameter 'connectorName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), connector_name: (encode-path-segment $connector_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors/{connector_name}") $qp $auth.query)
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

# Gets all the connector mappings in the specified connector.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings
# operationId: ConnectorMappings_ListByConnector
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($connector_name | is-empty) { error make --unspanned { msg: "path parameter 'connectorName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), connector_name: (encode-path-segment $connector_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors/{connector_name}/mappings") $qp $auth.query)
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

# Deletes a connector mapping in the connector.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# operationId: ConnectorMappings_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
  mapping_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($connector_name | is-empty) { error make --unspanned { msg: "path parameter 'connectorName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), connector_name: (encode-path-segment $connector_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors/{connector_name}/mappings/{mapping_name}") $qp $auth.query)
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

# Gets a connector mapping in the connector.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# operationId: ConnectorMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
  mapping_name: string
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
]: nothing -> record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($connector_name | is-empty) { error make --unspanned { msg: "path parameter 'connectorName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), connector_name: (encode-path-segment $connector_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors/{connector_name}/mappings/{mapping_name}") $qp $auth.query)
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

# Creates a connector mapping or updates an existing connector mapping in the connector.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/connectors/{connectorName}/mappings/{mappingName}
# operationId: ConnectorMappings_CreateOrUpdate
# --properties shape: {connectorType?: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, mappingProperties: any}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-connectors-mappings create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  connector_name: string
  mapping_name: string
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
  --properties: any # The connector mapping definition. — shape: {connectorType?: "None"|"CRM"|"AzureBlob"|"Salesforce"|"ExchangeOnline"|"Outbound", description?: string, displayName?: string, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, mappingProperties: any}
]: any -> record<properties: record<connectorMappingName: string, connectorName: string, connectorType: string, created: string, dataFormatId: string, description: string, displayName: string, entityType: string, entityTypeName: string, lastModified: string, mappingProperties: record<availability: record, completeOperation: record, errorManagement: record, fileFilter: string, folderPath: string, format: record, hasHeader: bool, structure: list>, nextRunTime: string, runId: string, state: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($connector_name | is-empty) { error make --unspanned { msg: "path parameter 'connectorName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), connector_name: (encode-path-segment $connector_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/connectors/{connector_name}/mappings/{mapping_name}") $qp $auth.query)
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 201]
}

# Gets data image upload URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getDataImageUploadUrl
# operationId: Images_GetUploadUrlForData
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-images-get-data-image-upload-url get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --entity-type: string # Type of entity. Can be Profile or Interaction.
  --entity-type-name: string # Name of the entity type.
  --relative-path: string # Relative path of the image.
]: any -> record<contentUrl: string, imageExists: bool, relativePath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/images/getDataImageUploadUrl") $qp $auth.query)
  let req_body = {"entityType": $entity_type, "entityTypeName": $entity_type_name, "relativePath": $relative_path} | compact
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

# Gets entity type (profile or interaction) image upload URL.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/images/getEntityTypeImageUploadUrl
# operationId: Images_GetUploadUrlForEntityType
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-images-get-entity-type-image-upload-url get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --entity-type: string # Type of entity. Can be Profile or Interaction.
  --entity-type-name: string # Name of the entity type.
  --relative-path: string # Relative path of the image.
]: any -> record<contentUrl: string, imageExists: bool, relativePath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/images/getEntityTypeImageUploadUrl") $qp $auth.query)
  let req_body = {"entityType": $entity_type, "entityTypeName": $entity_type_name, "relativePath": $relative_path} | compact
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

# Gets all interactions in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions
# operationId: Interactions_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of interaction to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/interactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale-code": $locale_code, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets information about the specified interaction.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}
# operationId: Interactions_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  interaction_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of interaction to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($interaction_name | is-empty) { error make --unspanned { msg: "path parameter 'interactionName' must be non-empty" } }
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), interaction_name: (encode-path-segment $interaction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/interactions/{interaction_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale-code": $locale_code, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates an interaction or updates an existing interaction within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}
# operationId: Interactions_CreateOrUpdate
# --properties shape: {defaultDataSource?: any, idPropertyNames?: list<string>, isActivity?: bool, participantProfiles?: list, primaryParticipantProfilePropertyName?: string, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  interaction_name: string
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
  --properties: any # The Interaction Type Definition — shape: {defaultDataSource?: any, idPropertyNames?: list<string>, isActivity?: bool, participantProfiles?: list, primaryParticipantProfilePropertyName?: string, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
]: any -> record<properties: record<dataSourcePrecedenceRules: list<record>, defaultDataSource: record<dataSourceReferenceId: string, dataSourceType: string, id: int, name: string, status: string>, idPropertyNames: list<string>, isActivity: bool, participantProfiles: list<record>, primaryParticipantProfilePropertyName: string, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($interaction_name | is-empty) { error make --unspanned { msg: "path parameter 'interactionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), interaction_name: (encode-path-segment $interaction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/interactions/{interaction_name}") $qp $auth.query)
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

# Suggests relationships to create relationship links.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/interactions/{interactionName}/suggestRelationshipLinks
# operationId: Interactions_SuggestRelationshipLinks
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-interactions-suggest-relationship-links create" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  interaction_name: string
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
]: nothing -> record<interactionName: string, suggestedRelationships: table<existingRelationshipName: string, profileName: string, profilePropertyReferences: list, relatedProfileName: string, relatedProfilePropertyReferences: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($interaction_name | is-empty) { error make --unspanned { msg: "path parameter 'interactionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), interaction_name: (encode-path-segment $interaction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/interactions/{interaction_name}/suggestRelationshipLinks") $qp $auth.query)
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

# Gets all the KPIs in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi
# operationId: Kpi_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/kpi") $qp $auth.query)
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

# Deletes a KPI in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# operationId: Kpi_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($kpi_name | is-empty) { error make --unspanned { msg: "path parameter 'kpiName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), kpi_name: (encode-path-segment $kpi_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/kpi/{kpi_name}") $qp $auth.query)
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

# Gets a KPI in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# operationId: Kpi_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
]: nothing -> record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($kpi_name | is-empty) { error make --unspanned { msg: "path parameter 'kpiName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), kpi_name: (encode-path-segment $kpi_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/kpi/{kpi_name}") $qp $auth.query)
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

# Creates a KPI or updates an existing KPI in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}
# operationId: Kpi_CreateOrUpdate
# --properties shape: {aliases?: list, calculationWindow: "Lifetime"|"Hour"|"Day"|"Week"|"Month", calculationWindowFieldName?: string, description?: record, displayName?: record, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, expression: string, extracts?: list, filter?: string, function: "Sum"|"Avg"|"Min"|"Max"|"Last"|"Count"|"None"|"CountDistinct", groupBy?: list<string>, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", ... (2 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
  --properties: any # Defines the KPI Threshold limits. — shape: {aliases?: list, calculationWindow: "Lifetime"|"Hour"|"Day"|"Week"|"Month", calculationWindowFieldName?: string, description?: record, displayName?: record, entityType: "None"|"Profile"|"Interaction"|"Relationship", entityTypeName: string, expression: string, extracts?: list, filter?: string, function: "Sum"|"Avg"|"Min"|"Max"|"Last"|"Count"|"None"|"CountDistinct", groupBy?: list<string>, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", ... (2 more fields)}
]: any -> record<properties: record<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($kpi_name | is-empty) { error make --unspanned { msg: "path parameter 'kpiName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), kpi_name: (encode-path-segment $kpi_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/kpi/{kpi_name}") $qp $auth.query)
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

# Reprocesses the Kpi values of the specified KPI.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/kpi/{kpiName}/reprocess
# operationId: Kpi_Reprocess
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-kpi-reprocess create" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  kpi_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($kpi_name | is-empty) { error make --unspanned { msg: "path parameter 'kpiName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), kpi_name: (encode-path-segment $kpi_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/kpi/{kpi_name}/reprocess") $qp $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Gets all the links in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links
# operationId: Links_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/links") $qp $auth.query)
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

# Deletes a link in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# operationId: Links_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  link_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($link_name | is-empty) { error make --unspanned { msg: "path parameter 'linkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), link_name: (encode-path-segment $link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/links/{link_name}") $qp $auth.query)
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

# Gets a link in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# operationId: Links_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  link_name: string
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
]: nothing -> record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($link_name | is-empty) { error make --unspanned { msg: "path parameter 'linkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), link_name: (encode-path-segment $link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/links/{link_name}") $qp $auth.query)
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

# Creates a link or updates an existing link in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/links/{linkName}
# operationId: Links_CreateOrUpdate
# --properties shape: {description?: record, displayName?: record, mappings?: list, operationType?: "Upsert"|"Delete", participantPropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", referenceOnly?: bool, sourceEntityType: "None"|"Profile"|"Interaction"|"Relationship", sourceEntityTypeName: string, targetEntityType: "None"|"Profile"|"Interaction"|"Relationship", targetEntityTypeName: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-links create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  link_name: string
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
  --properties: any # The definition of Link. — shape: {description?: record, displayName?: record, mappings?: list, operationType?: "Upsert"|"Delete", participantPropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", referenceOnly?: bool, sourceEntityType: "None"|"Profile"|"Interaction"|"Relationship", sourceEntityTypeName: string, targetEntityType: "None"|"Profile"|"Interaction"|"Relationship", targetEntityTypeName: string}
]: any -> record<properties: record<description: record, displayName: record, linkName: string, mappings: list<record>, operationType: string, participantPropertyReferences: list<record>, provisioningState: string, referenceOnly: bool, sourceEntityType: string, sourceEntityTypeName: string, targetEntityType: string, targetEntityTypeName: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($link_name | is-empty) { error make --unspanned { msg: "path parameter 'linkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), link_name: (encode-path-segment $link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/links/{link_name}") $qp $auth.query)
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

# Gets all the predictions in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions
# operationId: Predictions_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/predictions") $qp $auth.query)
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

# Deletes a Prediction in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# operationId: Predictions_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($prediction_name | is-empty) { error make --unspanned { msg: "path parameter 'predictionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), prediction_name: (encode-path-segment $prediction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/predictions/{prediction_name}") $qp $auth.query)
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

# Gets a Prediction in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# operationId: Predictions_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
]: nothing -> record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($prediction_name | is-empty) { error make --unspanned { msg: "path parameter 'predictionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), prediction_name: (encode-path-segment $prediction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/predictions/{prediction_name}") $qp $auth.query)
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

# Creates a Prediction or updates an existing Prediction in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}
# operationId: Predictions_CreateOrUpdate
# --properties shape: {autoAnalyze: bool, description?: record, displayName?: record, grades?: list, involvedInteractionTypes?: list<string>, involvedKpiTypes?: list<string>, involvedRelationships?: list<string>, mappings: record, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName?: string, primaryProfileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", scopeExpression: string, scoreLabel: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
  --properties: any # The prediction definition. — shape: {autoAnalyze: bool, description?: record, displayName?: record, grades?: list, involvedInteractionTypes?: list<string>, involvedKpiTypes?: list<string>, involvedRelationships?: list<string>, mappings: record, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName?: string, primaryProfileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", scopeExpression: string, scoreLabel: string}
]: any -> record<properties: record<autoAnalyze: bool, description: record, displayName: record, grades: list<record>, involvedInteractionTypes: list<string>, involvedKpiTypes: list<string>, involvedRelationships: list<string>, mappings: record<grade: string, reason: string, score: string>, negativeOutcomeExpression: string, positiveOutcomeExpression: string, predictionName: string, primaryProfileType: string, provisioningState: string, scopeExpression: string, scoreLabel: string, systemGeneratedEntities: record<generatedInteractionTypes: list, generatedKpis: record, generatedLinks: list>, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($prediction_name | is-empty) { error make --unspanned { msg: "path parameter 'predictionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), prediction_name: (encode-path-segment $prediction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/predictions/{prediction_name}") $qp $auth.query)
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

# Gets model status of the prediction.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getModelStatus
# operationId: Predictions_GetModelStatus
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions-get-model-status get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
]: nothing -> record<message: string, modelVersion: string, predictionGuidId: string, predictionName: string, signalsUsed: int, status: string, tenantId: string, testSetCount: int, trainingAccuracy: int, trainingSetCount: int, validationSetCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($prediction_name | is-empty) { error make --unspanned { msg: "path parameter 'predictionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), prediction_name: (encode-path-segment $prediction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/predictions/{prediction_name}/getModelStatus") $qp $auth.query)
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

# Gets training results.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/getTrainingResults
# operationId: Predictions_GetTrainingResults
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions-get-training-results get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
]: nothing -> record<canonicalProfiles: table<canonicalProfileId: int, properties: list>, predictionDistribution: record<distributions: list<record>, totalNegatives: int, totalPositives: int>, primaryProfileInstanceCount: int, scoreName: string, tenantId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($prediction_name | is-empty) { error make --unspanned { msg: "path parameter 'predictionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), prediction_name: (encode-path-segment $prediction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/predictions/{prediction_name}/getTrainingResults") $qp $auth.query)
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

# Creates or updates the model status of prediction.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/predictions/{predictionName}/modelStatus
# operationId: Predictions_ModelStatus
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-predictions-model-status create" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  prediction_name: string
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
  status: string@status-completer # Prediction model life cycle. When prediction is in PendingModelConfirmation status, it is allowed to update the status to PendingFeaturing or Active through API.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($prediction_name | is-empty) { error make --unspanned { msg: "path parameter 'predictionName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), prediction_name: (encode-path-segment $prediction_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/predictions/{prediction_name}/modelStatus") $qp $auth.query)
  let req_body = {"status": $status} | compact
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

# Gets all profile in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles
# operationId: Profiles_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/profiles") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale-code": $locale_code, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a profile within a hub
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# operationId: Profiles_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($profile_name | is-empty) { error make --unspanned { msg: "path parameter 'profileName' must be non-empty" } }
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), profile_name: (encode-path-segment $profile_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/profiles/{profile_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"locale-code": $locale_code, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets information about the specified profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# operationId: Profiles_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-code: string # Locale of profile to retrieve, default is en-us. (default: en-us)
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($profile_name | is-empty) { error make --unspanned { msg: "path parameter 'profileName' must be non-empty" } }
  let qp = [(serialize-qp "locale-code" $locale_code "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), profile_name: (encode-path-segment $profile_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/profiles/{profile_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale-code": $locale_code, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a profile within a Hub, or updates an existing profile.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}
# operationId: Profiles_CreateOrUpdate
# --properties shape: {strongIds?: list, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
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
  --properties: any # The profile type definition. — shape: {strongIds?: list, apiEntitySetName?: string, entityType?: "None"|"Profile"|"Interaction"|"Relationship", fields?: list, instancesCount?: int, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", schemaItemTypeLink?: string, timestampFieldName?: string, typeName?: string}
]: any -> record<properties: record<strongIds: list<record>, apiEntitySetName: string, entityType: string, fields: list<record>, instancesCount: int, lastChangedUtc: string, provisioningState: string, schemaItemTypeLink: string, tenantId: string, timestampFieldName: string, typeName: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($profile_name | is-empty) { error make --unspanned { msg: "path parameter 'profileName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), profile_name: (encode-path-segment $profile_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/profiles/{profile_name}") $qp $auth.query)
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

# Gets the KPIs that enrich the profile Type identified by the supplied name. Enrichment happens through participants of the Interaction on an Interaction KPI and through Relationships for Profile KPIs.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/profiles/{profileName}/getEnrichingKpis
# operationId: Profiles_GetEnrichingKpis
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-profiles-get-enriching-kpis get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  profile_name: string
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
]: nothing -> table<aliases: list<record>, calculationWindow: string, calculationWindowFieldName: string, description: record, displayName: record, entityType: string, entityTypeName: string, expression: string, extracts: list<record>, filter: string, function: string, groupBy: list<string>, groupByMetadata: list<record>, kpiName: string, participantProfilesMetadata: list<record>, provisioningState: string, tenantId: string, thresHolds: record<increasingKpi: bool, lowerLimit: float, upperLimit: float>, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($profile_name | is-empty) { error make --unspanned { msg: "path parameter 'profileName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), profile_name: (encode-path-segment $profile_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/profiles/{profile_name}/getEnrichingKpis") $qp $auth.query)
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

# Gets all relationship links in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks
# operationId: RelationshipLinks_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationshipLinks") $qp $auth.query)
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

# Deletes a relationship link within a hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# operationId: RelationshipLinks_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_link_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($relationship_link_name | is-empty) { error make --unspanned { msg: "path parameter 'relationshipLinkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), relationship_link_name: (encode-path-segment $relationship_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationshipLinks/{relationship_link_name}") $qp $auth.query)
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

# Gets information about the specified relationship Link.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# operationId: RelationshipLinks_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_link_name: string
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
]: nothing -> record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($relationship_link_name | is-empty) { error make --unspanned { msg: "path parameter 'relationshipLinkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), relationship_link_name: (encode-path-segment $relationship_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationshipLinks/{relationship_link_name}") $qp $auth.query)
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

# Creates a relationship link or updates an existing relationship link within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationshipLinks/{relationshipLinkName}
# operationId: RelationshipLinks_CreateOrUpdate
# --properties shape: {description?: record, displayName?: record, interactionType: string, mappings?: list, profilePropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfilePropertyReferences: list, relationshipName: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationship-links create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_link_name: string
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
  --properties: any # The definition of relationship link. — shape: {description?: record, displayName?: record, interactionType: string, mappings?: list, profilePropertyReferences: list, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfilePropertyReferences: list, relationshipName: string}
]: any -> record<properties: record<description: record, displayName: record, interactionType: string, linkName: string, mappings: list<record>, profilePropertyReferences: list<record>, provisioningState: string, relatedProfilePropertyReferences: list<record>, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($relationship_link_name | is-empty) { error make --unspanned { msg: "path parameter 'relationshipLinkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), relationship_link_name: (encode-path-segment $relationship_link_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationshipLinks/{relationship_link_name}") $qp $auth.query)
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

# Gets all relationships in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships
# operationId: Relationships_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationships") $qp $auth.query)
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

# Deletes a relationship within a hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# operationId: Relationships_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($relationship_name | is-empty) { error make --unspanned { msg: "path parameter 'relationshipName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), relationship_name: (encode-path-segment $relationship_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationships/{relationship_name}") $qp $auth.query)
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

# Gets information about the specified relationship.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# operationId: Relationships_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_name: string
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
]: nothing -> record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($relationship_name | is-empty) { error make --unspanned { msg: "path parameter 'relationshipName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), relationship_name: (encode-path-segment $relationship_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationships/{relationship_name}") $qp $auth.query)
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

# Creates a relationship or updates an existing relationship within a hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/relationships/{relationshipName}
# operationId: Relationships_CreateOrUpdate
# --properties shape: {cardinality?: "OneToOne"|"OneToMany"|"ManyToMany", description?: record, displayName?: record, expiryDateTimeUtc?: string, fields?: list, lookupMappings?: list, profileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfileType: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-relationships create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  relationship_name: string
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
  --properties: any # The definition of Relationship. — shape: {cardinality?: "OneToOne"|"OneToMany"|"ManyToMany", description?: record, displayName?: record, expiryDateTimeUtc?: string, fields?: list, lookupMappings?: list, profileType: string, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relatedProfileType: string}
]: any -> record<properties: record<cardinality: string, description: record, displayName: record, expiryDateTimeUtc: string, fields: list<record>, lookupMappings: list<record>, profileType: string, provisioningState: string, relatedProfileType: string, relationshipGuidId: string, relationshipName: string, tenantId: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($relationship_name | is-empty) { error make --unspanned { msg: "path parameter 'relationshipName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), relationship_name: (encode-path-segment $relationship_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/relationships/{relationship_name}") $qp $auth.query)
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

# Gets all the role assignments for the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments
# operationId: RoleAssignments_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/roleAssignments") $qp $auth.query)
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

# Deletes the role assignment in the hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# operationId: RoleAssignments_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  assignment_name: string
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
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($assignment_name | is-empty) { error make --unspanned { msg: "path parameter 'assignmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), assignment_name: (encode-path-segment $assignment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/roleAssignments/{assignment_name}") $qp $auth.query)
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

# Gets the role assignment in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# operationId: RoleAssignments_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  assignment_name: string
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
]: nothing -> record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($assignment_name | is-empty) { error make --unspanned { msg: "path parameter 'assignmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), assignment_name: (encode-path-segment $assignment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/roleAssignments/{assignment_name}") $qp $auth.query)
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

# Creates or updates a role assignment in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roleAssignments/{assignmentName}
# operationId: RoleAssignments_CreateOrUpdate
# --properties shape: {conflationPolicies?: any, connectors?: any, description?: record, displayName?: record, interactions?: any, kpis?: any, links?: any, principals: list, profiles?: any, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relationshipLinks?: any, relationships?: any, role: "Admin"|"Reader"|"ManageAdmin"|"ManageReader"|"DataAdmin"|"DataReader", roleAssignments?: any, sasPolicies?: any, segments?: any, views?: any, widgetTypes?: any}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-role-assignments create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  assignment_name: string
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
  --properties: any # The Role Assignment definition. — shape: {conflationPolicies?: any, connectors?: any, description?: record, displayName?: record, interactions?: any, kpis?: any, links?: any, principals: list, profiles?: any, provisioningState?: "Provisioning"|"Succeeded"|"Expiring"|"Deleting"|"HumanIntervention"|"Failed", relationshipLinks?: any, relationships?: any, role: "Admin"|"Reader"|"ManageAdmin"|"ManageReader"|"DataAdmin"|"DataReader", roleAssignments?: any, sasPolicies?: any, segments?: any, views?: any, widgetTypes?: any}
]: any -> record<properties: record<assignmentName: string, conflationPolicies: record<elements: list, exceptions: list>, connectors: record<elements: list, exceptions: list>, description: record, displayName: record, interactions: record<elements: list, exceptions: list>, kpis: record<elements: list, exceptions: list>, links: record<elements: list, exceptions: list>, principals: list<record>, profiles: record<elements: list, exceptions: list>, provisioningState: string, relationshipLinks: record<elements: list, exceptions: list>, relationships: record<elements: list, exceptions: list>, role: string, roleAssignments: record<elements: list, exceptions: list>, sasPolicies: record<elements: list, exceptions: list>, segments: record<elements: list, exceptions: list>, tenantId: string, views: record<elements: list, exceptions: list>, widgetTypes: record<elements: list, exceptions: list>>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($assignment_name | is-empty) { error make --unspanned { msg: "path parameter 'assignmentName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), assignment_name: (encode-path-segment $assignment_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/roleAssignments/{assignment_name}") $qp $auth.query)
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

# Gets all the roles for the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/roles
# operationId: Roles_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-roles list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/roles") $qp $auth.query)
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

# Gets all available views for given user in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views
# operationId: Views_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
  --user-id: string # The user ID. Use * to retrieve hub level views.
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "userId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/views") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "userId": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a view in the specified hub.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# operationId: Views_Delete
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views delete" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  view_name: string
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
  --user-id: string # The user ID. Use * to retrieve hub level view.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($view_name | is-empty) { error make --unspanned { msg: "path parameter 'viewName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "userId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), view_name: (encode-path-segment $view_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/views/{view_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"api-version": $api_version, "userId": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets a view in the hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# operationId: Views_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  view_name: string
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
  --user-id: string # The user ID. Use * to retrieve hub level view.
]: nothing -> record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($view_name | is-empty) { error make --unspanned { msg: "path parameter 'viewName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "userId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), view_name: (encode-path-segment $view_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/views/{view_name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "userId": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a view or updates an existing view in the hub.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/views/{viewName}
# operationId: Views_CreateOrUpdate
# --properties shape: {definition: string, displayName?: record, userId?: string}
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-views create-or-update" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  view_name: string
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
  --properties: any # The view in Customer 360 web application. — shape: {definition: string, displayName?: record, userId?: string}
]: any -> record<properties: record<changed: string, created: string, definition: string, displayName: record, tenantId: string, userId: string, viewName: string>, id: string, name: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($view_name | is-empty) { error make --unspanned { msg: "path parameter 'viewName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), view_name: (encode-path-segment $view_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/views/{view_name}") $qp $auth.query)
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

# Gets all available widget types in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes
# operationId: WidgetTypes_ListByHub
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-widget-types list" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
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
]: nothing -> record<nextLink: string, value: table<properties: record, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/widgetTypes") $qp $auth.query)
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

# Gets a widget type in the specified hub.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.CustomerInsights/hubs/{hubName}/widgetTypes/{widgetTypeName}
# operationId: WidgetTypes_Get
export def "subscriptions-resource-groups-providers-microsoft-customer-insights-hubs-widget-types get" [
  subscription_id: string
  resource_group_name: string
  hub_name: string
  widget_type_name: string
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
]: nothing -> record<properties: record<changed: string, created: string, definition: string, description: string, displayName: record, imageUrl: string, tenantId: string, widgetTypeName: string, widgetVersion: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($hub_name | is-empty) { error make --unspanned { msg: "path parameter 'hubName' must be non-empty" } }
  if ($widget_type_name | is-empty) { error make --unspanned { msg: "path parameter 'widgetTypeName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), hub_name: (encode-path-segment $hub_name), widget_type_name: (encode-path-segment $widget_type_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.CustomerInsights/hubs/{hub_name}/widgetTypes/{widget_type_name}") $qp $auth.query)
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
