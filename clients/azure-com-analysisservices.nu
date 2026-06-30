# Auto-generated client for AzureAnalysisServices v2017-08-01
# Source: https://api.apis.guru/v2/specs/azure.com/analysisservices/2017-08-01/swagger.json
# Auth: --token flag or $env.AZUREANALYSISSERVICES_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AZUREANALYSISSERVICES_TOKEN | default "" }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-analysis-services-operations list" } } | get name | first)
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

# Lists all of the available consumption REST API operations.
#
# GET /providers/Microsoft.AnalysisServices/operations
# operationId: Operations_List
export def "providers-microsoft-analysis-services-operations list" [
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
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.AnalysisServices/operations" $qp $auth.query)
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

# Check the name availability in the target location.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.AnalysisServices/locations/{location}/checkNameAvailability
# operationId: Servers_CheckNameAvailability
export def "subscriptions-providers-microsoft-analysis-services-locations-check-name-availability check-servers" [
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
  --api-version: string # The client API version.
  --name: string # Name for checking availability.
  --type: string # The resource type of azure analysis services. (default: Microsoft.AnalysisServices/servers)
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location: (encode-path-segment $location)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AnalysisServices/locations/{location}/checkNameAvailability") $qp $auth.query)
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

# List the result of the specified operation.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AnalysisServices/locations/{location}/operationresults/{operationId}
# operationId: Servers_ListOperationResults
export def "subscriptions-providers-microsoft-analysis-services-locations-operationresults list-servers-operation-results" [
  subscription_id: string
  location: string
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
  --api-version: string # The client API version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location: (encode-path-segment $location), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AnalysisServices/locations/{location}/operationresults/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# List the status of operation.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AnalysisServices/locations/{location}/operationstatuses/{operationId}
# operationId: Servers_ListOperationStatuses
export def "subscriptions-providers-microsoft-analysis-services-locations-operationstatuses list-servers-operation-statuses" [
  subscription_id: string
  location: string
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
  --api-version: string # The client API version.
]: nothing -> record<endTime: string, error: record<code: string, message: string>, id: string, name: string, startTime: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($operation_id | is-empty) { error make --unspanned { msg: "path parameter 'operationId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location: (encode-path-segment $location), operation_id: (encode-path-segment $operation_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AnalysisServices/locations/{location}/operationstatuses/{operation_id}") $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Lists all the Analysis Services servers for the given subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AnalysisServices/servers
# operationId: Servers_List
export def "subscriptions-providers-microsoft-analysis-services-servers list" [
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
  --api-version: string # The client API version.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AnalysisServices/servers") $qp $auth.query)
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

# Lists eligible SKUs for Analysis Services resource provider.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.AnalysisServices/skus
# operationId: Servers_ListSkusForNew
export def "subscriptions-providers-microsoft-analysis-services-skus list-servers-for-new" [
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
  --api-version: string # The client API version.
]: nothing -> record<value: table<capacity: int, name: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.AnalysisServices/skus") $qp $auth.query)
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

# Gets all the Analysis Services servers for the given resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers
# operationId: Servers_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers list" [
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
  --api-version: string # The client API version.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers") $qp $auth.query)
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

# Deletes the specified Analysis Services server.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}
# operationId: Servers_Delete
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers delete" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}") $qp $auth.query)
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

# Gets details about the specified Analysis Services server.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}
# operationId: Servers_GetDetails
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers get-details" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
]: nothing -> record<properties: record<provisioningState: string, serverFullName: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}") $qp $auth.query)
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

# Updates the current state of the specified Analysis Services server.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}
# operationId: Servers_Update
# --properties shape: {asAdministrators?: record, backupBlobContainerUri?: string, gatewayDetails?: record, ipV4FirewallSettings?: record, querypoolConnectionMode?: "All"|"ReadOnly"}
# --sku shape: {capacity?: int, name: string, tier?: "Development"|"Basic"|"Standard"}
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers update" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
  --properties: record # An object that represents a set of mutable Analysis Services resource properties. — shape: {asAdministrators?: record, backupBlobContainerUri?: string, gatewayDetails?: record, ipV4FirewallSettings?: record, querypoolConnectionMode?: "All"|"ReadOnly"}
  --sku: record # Represents the SKU name and Azure pricing tier for Analysis Services resource. — shape: {capacity?: int, name: string, tier?: "Development"|"Basic"|"Standard"}
  --tags: record # Key-value pairs of additional provisioning properties.
]: any -> record<properties: record<provisioningState: string, serverFullName: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "sku": $sku, "tags": $tags} | compact
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

# Provisions the specified Analysis Services server based on the configuration specified in the request.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}
# operationId: Servers_Create
# --properties shape: {asAdministrators?: record, backupBlobContainerUri?: string, gatewayDetails?: record, ipV4FirewallSettings?: record, querypoolConnectionMode?: "All"|"ReadOnly"}
# --sku shape: {capacity?: int, name: string, tier?: "Development"|"Basic"|"Standard"}
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers create" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
  --properties: record # Properties of Analysis Services resource. — shape: {asAdministrators?: record, backupBlobContainerUri?: string, gatewayDetails?: record, ipV4FirewallSettings?: record, querypoolConnectionMode?: "All"|"ReadOnly"}
  location: string # Location of the Analysis Services resource.
  sku: record # Represents the SKU name and Azure pricing tier for Analysis Services resource. — shape: {capacity?: int, name: string, tier?: "Development"|"Basic"|"Standard"}
  --tags: record # Key-value pairs of additional resource provisioning properties.
]: any -> record<properties: record<provisioningState: string, serverFullName: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}") $qp $auth.query)
  let req_body = {"properties": $properties, "location": $location, "sku": $sku, "tags": $tags} | compact
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

# Dissociates a Unified Gateway associated with the server.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}/dissociateGateway
# operationId: Servers_DissociateGateway
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers-dissociate-gateway create" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}/dissociateGateway") $qp $auth.query)
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

# Return the gateway status of the specified Analysis Services server instance.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}/listGatewayStatus
# operationId: Servers_ListGatewayStatus
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers-list-gateway-status list" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}/listGatewayStatus") $qp $auth.query)
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

# Resumes operation of the specified Analysis Services server instance.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}/resume
# operationId: Servers_Resume
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers-resume create" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}/resume") $qp $auth.query)
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

# Lists eligible SKUs for an Analysis Services resource.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}/skus
# operationId: Servers_ListSkusForExisting
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers-skus list-for-existing" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
]: nothing -> record<value: table<sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}/skus") $qp $auth.query)
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

# Suspends operation of the specified Analysis Services server instance.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.AnalysisServices/servers/{serverName}/suspend
# operationId: Servers_Suspend
export def "subscriptions-resource-groups-providers-microsoft-analysis-services-servers-suspend create" [
  subscription_id: string
  resource_group_name: string
  server_name: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($server_name | is-empty) { error make --unspanned { msg: "path parameter 'serverName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), server_name: (encode-path-segment $server_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.AnalysisServices/servers/{server_name}/suspend") $qp $auth.query)
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
