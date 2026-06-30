# Auto-generated client for DevTestLabsClient v2018-09-15
# Source: https://api.apis.guru/v2/specs/azure.com/devtestlabs-DTL/2018-09-15/swagger.json
# Auth: --token flag or $env.DEVTESTLABSCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o DEVTESTLABSCLIENT_TOKEN | default "" }
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
def file-upload-options-completer [] { ["None" "UploadFilesAndGenerateSasTokens"] }
def event-name-completer [] { ["AutoShutdown" "Cost"] }
def host-caching-completer [] { ["None" "ReadOnly" "ReadWrite"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-dev-test-lab-operations list" } } | get name | first)
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

# Result of the request to list REST API operations
#
# GET /providers/Microsoft.DevTestLab/operations
# operationId: ProviderOperations_List
export def "providers-microsoft-dev-test-lab-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DevTestLab/operations" $qp $auth.query)
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

# List labs in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/labs
# operationId: Labs_ListBySubscription
export def "subscriptions-providers-microsoft-dev-test-lab-labs list" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DevTestLab/labs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get operation.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/locations/{locationName}/operations/{name}
# operationId: Operations_Get
export def "subscriptions-providers-microsoft-dev-test-lab-locations-operations get" [
  subscription_id: string
  location_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, message: string>, status: string, statusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($location_name | is-empty) { error make --unspanned { msg: "path parameter 'locationName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), location_name: (encode-path-segment $location_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DevTestLab/locations/{location_name}/operations/{name}") $qp $auth.query)
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

# List schedules in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DevTestLab/schedules
# operationId: GlobalSchedules_ListBySubscription
export def "subscriptions-providers-microsoft-dev-test-lab-schedules list-global" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.DevTestLab/schedules") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List labs in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs
# operationId: Labs_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs list" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List artifact sources in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources
# operationId: ArtifactSources_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources list-artifact-sources" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List azure resource manager templates in a given artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates
# operationId: ArmTemplates_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-armtemplates list-arm-templates" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($artifact_source_name | is-empty) { error make --unspanned { msg: "path parameter 'artifactSourceName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), artifact_source_name: (encode-path-segment $artifact_source_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{artifact_source_name}/armtemplates") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get azure resource manager template.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/armtemplates/{name}
# operationId: ArmTemplates_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-armtemplates get-arm-templates" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<contents: record, createdDate: string, description: string, displayName: string, enabled: bool, icon: string, parametersValueFilesInfo: list<record>, publisher: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($artifact_source_name | is-empty) { error make --unspanned { msg: "path parameter 'artifactSourceName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), artifact_source_name: (encode-path-segment $artifact_source_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{artifact_source_name}/armtemplates/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List artifacts in a given artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts
# operationId: Artifacts_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-artifacts list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=title)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($artifact_source_name | is-empty) { error make --unspanned { msg: "path parameter 'artifactSourceName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), artifact_source_name: (encode-path-segment $artifact_source_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{artifact_source_name}/artifacts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get artifact.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}
# operationId: Artifacts_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-artifacts get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=title)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, description: string, filePath: string, icon: string, parameters: record, publisher: string, targetOsType: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($artifact_source_name | is-empty) { error make --unspanned { msg: "path parameter 'artifactSourceName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), artifact_source_name: (encode-path-segment $artifact_source_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{artifact_source_name}/artifacts/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generates an ARM template for the given artifact, uploads the required files to a storage account, and validates the generated artifact.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{artifactSourceName}/artifacts/{name}/generateArmTemplate
# operationId: Artifacts_GenerateArmTemplate
# --parameters item shape: {name?: string, value?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources-artifacts-generate-arm-template generate" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  artifact_source_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --file-upload-options: string@file-upload-options-completer # Options for uploading the files for the artifact. UploadFilesAndGenerateSasTokens is the default value.
  --location: string # The location of the virtual machine.
  --parameters: list # The parameters of the ARM template. — item shape: {name?: string, value?: string}
  --virtual-machine-name: string # The resource name of the virtual machine.
]: any -> record<parameters: record, template: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($artifact_source_name | is-empty) { error make --unspanned { msg: "path parameter 'artifactSourceName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), artifact_source_name: (encode-path-segment $artifact_source_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{artifact_source_name}/artifacts/{name}/generateArmTemplate") $qp $auth.query)
  let req_body = {"fileUploadOptions": $file_upload_options, "location": $location, "parameters": $parameters, "virtualMachineName": $virtual_machine_name} | compact
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

# Delete artifact source.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources delete-artifact-sources" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{name}") $qp $auth.query)
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

# Get artifact source.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources get-artifact-sources" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=displayName)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of artifact sources. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_Update
# --properties shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources update-artifact-sources" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of an artifact source. — shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{name}") $qp $auth.query)
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

# Create or replace an existing artifact source.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/artifactsources/{name}
# operationId: ArtifactSources_CreateOrUpdate
# --properties shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-artifactsources create-artifact-sources-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of an artifact source. — shape: {armTemplateFolderPath?: string, branchRef?: string, displayName?: string, folderPath?: string, securityToken?: string, sourceType?: "VsoGit"|"GitHub", status?: "Enabled"|"Disabled", uri?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateFolderPath: string, branchRef: string, createdDate: string, displayName: string, folderPath: string, provisioningState: string, securityToken: string, sourceType: string, status: string, uniqueIdentifier: string, uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/artifactsources/{name}") $qp $auth.query)
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

# Get cost.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}
# operationId: Costs_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-costs get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=labCostDetails)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/costs/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create or replace an existing cost.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/costs/{name}
# operationId: Costs_CreateOrUpdate
# --properties shape: {createdDate?: string, currencyCode?: string, endDateTime?: string, labCostSummary?: record, startDateTime?: string, targetCost?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-costs create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a cost item. — shape: {createdDate?: string, currencyCode?: string, endDateTime?: string, labCostSummary?: record, startDateTime?: string, targetCost?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, currencyCode: string, endDateTime: string, labCostDetails: list<record>, labCostSummary: record<estimatedLabCost: float>, provisioningState: string, resourceCosts: list<record>, startDateTime: string, targetCost: record<costThresholds: list, cycleEndDateTime: string, cycleStartDateTime: string, cycleType: string, status: string, target: int>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/costs/{name}") $qp $auth.query)
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

# List custom images in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages
# operationId: CustomImages_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages list-custom-images" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=vm)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/customimages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete custom image. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages delete-custom-images" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/customimages/{name}") $qp $auth.query)
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

# Get custom image.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages get-custom-images" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=vm)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/customimages/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of custom images. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_Update
# --properties shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages update-custom-images" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a custom image. — shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/customimages/{name}") $qp $auth.query)
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

# Create or replace an existing custom image. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/customimages/{name}
# operationId: CustomImages_CreateOrUpdate
# --properties shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-customimages create-custom-images-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a custom image. — shape: {author?: string, customImagePlan?: record, dataDiskStorageInfo?: list, description?: string, isPlanAuthorized?: bool, managedImageId?: string, managedSnapshotId?: string, vhd?: record, vm?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, customImagePlan: record<id: string, offer: string, publisher: string>, dataDiskStorageInfo: list<record>, description: string, isPlanAuthorized: bool, managedImageId: string, managedSnapshotId: string, provisioningState: string, uniqueIdentifier: string, vhd: record<imageName: string, osType: string, sysPrep: bool>, vm: record<linuxOsInfo: record, sourceVmId: string, windowsOsInfo: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/customimages/{name}") $qp $auth.query)
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

# List formulas in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas
# operationId: Formulas_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/formulas") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete formula.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/formulas/{name}") $qp $auth.query)
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

# Get formula.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/formulas/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of formulas. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_Update
# --properties shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a formula. — shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/formulas/{name}") $qp $auth.query)
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

# Create or replace an existing formula. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/formulas/{name}
# operationId: Formulas_CreateOrUpdate
# --properties shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-formulas create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a formula. — shape: {author?: string, description?: string, formulaContent?: record, osType?: string, vm?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<author: string, creationDate: string, description: string, formulaContent: record<location: string, name: string, properties: record, tags: record>, osType: string, provisioningState: string, uniqueIdentifier: string, vm: record<labVmId: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/formulas/{name}") $qp $auth.query)
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

# List gallery images in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/galleryimages
# operationId: GalleryImages_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-galleryimages list-gallery-images" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=author)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/galleryimages") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List notification channels in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels
# operationId: NotificationChannels_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels list-notification-channels" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=webHookUrl)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/notificationchannels") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete notification channel.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels delete-notification-channels" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/notificationchannels/{name}") $qp $auth.query)
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

# Get notification channel.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels get-notification-channels" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=webHookUrl)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/notificationchannels/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of notification channels. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_Update
# --properties shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels update-notification-channels" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/notificationchannels/{name}") $qp $auth.query)
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

# Create or replace an existing notification channel.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}
# operationId: NotificationChannels_CreateOrUpdate
# --properties shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels create-notification-channels-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {description?: string, emailRecipient?: string, events?: list, notificationLocale?: string, webHookUrl?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, emailRecipient: string, events: list<record>, notificationLocale: string, provisioningState: string, uniqueIdentifier: string, webHookUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/notificationchannels/{name}") $qp $auth.query)
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

# Send notification to provided channel.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/notificationchannels/{name}/notify
# operationId: NotificationChannels_Notify
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-notificationchannels-notify notify-notification-channels" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --event-name: string@event-name-completer # The type of event (i.e. AutoShutdown, Cost)
  --json-payload: string # Properties for the notification in json format.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/notificationchannels/{name}/notify") $qp $auth.query)
  let req_body = {"eventName": $event_name, "jsonPayload": $json_payload} | compact
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

# Evaluates lab policy.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{name}/evaluatePolicies
# operationId: PolicySets_EvaluatePolicies
# --policies item shape: {factData?: string, factName?: string, userObjectId?: string, valueOffset?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-evaluate-policies create-policy-sets" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --policies: list # Policies to evaluate. — item shape: {factData?: string, factName?: string, userObjectId?: string, valueOffset?: string}
]: any -> record<results: table<hasError: bool, policyViolations: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/policysets/{name}/evaluatePolicies") $qp $auth.query)
  let req_body = {"policies": $policies} | compact
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

# List policies in a given policy set.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies
# operationId: Policies_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($policy_set_name | is-empty) { error make --unspanned { msg: "path parameter 'policySetName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), policy_set_name: (encode-path-segment $policy_set_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/policysets/{policy_set_name}/policies") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete policy.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($policy_set_name | is-empty) { error make --unspanned { msg: "path parameter 'policySetName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), policy_set_name: (encode-path-segment $policy_set_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/policysets/{policy_set_name}/policies/{name}") $qp $auth.query)
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

# Get policy.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=description)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($policy_set_name | is-empty) { error make --unspanned { msg: "path parameter 'policySetName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), policy_set_name: (encode-path-segment $policy_set_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/policysets/{policy_set_name}/policies/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of policies. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_Update
# --properties shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a Policy. — shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($policy_set_name | is-empty) { error make --unspanned { msg: "path parameter 'policySetName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), policy_set_name: (encode-path-segment $policy_set_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/policysets/{policy_set_name}/policies/{name}") $qp $auth.query)
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

# Create or replace an existing policy.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/policysets/{policySetName}/policies/{name}
# operationId: Policies_CreateOrUpdate
# --properties shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-policysets-policies create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  policy_set_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a Policy. — shape: {description?: string, evaluatorType?: "AllowedValuesPolicy"|"MaxValuePolicy", factData?: string, factName?: "UserOwnedLabVmCount"|"UserOwnedLabPremiumVmCount"|"LabVmCount"|"LabPremiumVmCount"|"LabVmSize"|"GalleryImage"|"UserOwnedLabVmCountInSubnet"|"LabTargetCost"|"EnvironmentTemplate"|"ScheduleEditPermission", status?: "Enabled"|"Disabled", threshold?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, description: string, evaluatorType: string, factData: string, factName: string, provisioningState: string, status: string, threshold: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($policy_set_name | is-empty) { error make --unspanned { msg: "path parameter 'policySetName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), policy_set_name: (encode-path-segment $policy_set_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/policysets/{policy_set_name}/policies/{name}") $qp $auth.query)
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

# List schedules in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules
# operationId: Schedules_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/schedules") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/schedules/{name}") $qp $auth.query)
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

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/schedules/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/schedules/{name}") $qp $auth.query)
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

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}
# operationId: Schedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/schedules/{name}") $qp $auth.query)
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

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/execute
# operationId: Schedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules-execute create" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/schedules/{name}/execute") $qp $auth.query)
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

# Lists all applicable schedules
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/schedules/{name}/listApplicable
# operationId: Schedules_ListApplicable
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-schedules-list-applicable list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/schedules/{name}/listApplicable") $qp $auth.query)
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

# Delete service runner.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# operationId: ServiceRunners_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-servicerunners delete-service-runners" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/servicerunners/{name}") $qp $auth.query)
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

# Get service runner.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# operationId: ServiceRunners_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-servicerunners get-service-runners" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/servicerunners/{name}") $qp $auth.query)
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

# Create or replace an existing service runner.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/servicerunners/{name}
# operationId: ServiceRunners_CreateOrUpdate
# --identity shape: {clientSecretUrl?: string, principalId?: string, tenantId?: string, type?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-servicerunners create-service-runners-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --identity: record # Properties of a managed identity — shape: {clientSecretUrl?: string, principalId?: string, tenantId?: string, type?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<identity: record<clientSecretUrl: string, principalId: string, tenantId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/servicerunners/{name}") $qp $auth.query)
  let req_body = {"identity": $identity, "location": $location, "tags": $tags} | compact
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

# List user profiles in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users
# operationId: Users_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=identity)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete user profile. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{name}") $qp $auth.query)
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

# Get user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=identity)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of user profiles. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_Update
# --properties shape: {identity?: record, secretStore?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab user profile. — shape: {identity?: record, secretStore?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{name}") $qp $auth.query)
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

# Create or replace an existing user profile. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{name}
# operationId: Users_CreateOrUpdate
# --properties shape: {identity?: record, secretStore?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab user profile. — shape: {identity?: record, secretStore?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, identity: record<appId: string, objectId: string, principalId: string, principalName: string, tenantId: string>, provisioningState: string, secretStore: record<keyVaultId: string, keyVaultUri: string>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{name}") $qp $auth.query)
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

# List disks in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks
# operationId: Disks_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=diskType)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/disks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete disk. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/disks/{name}") $qp $auth.query)
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

# Get disk.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=diskType)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/disks/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of disks. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_Update
# --properties shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a disk. — shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/disks/{name}") $qp $auth.query)
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

# Create or replace an existing disk. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}
# operationId: Disks_CreateOrUpdate
# --properties shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a disk. — shape: {diskBlobName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD", diskUri?: string, hostCaching?: string, leasedByLabVmId?: string, managedDiskId?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, diskBlobName: string, diskSizeGiB: int, diskType: string, diskUri: string, hostCaching: string, leasedByLabVmId: string, managedDiskId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/disks/{name}") $qp $auth.query)
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

# Attach and create the lease of the disk to the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/attach
# operationId: Disks_Attach
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks-attach attach" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --leased-by-lab-vm-id: string # The resource ID of the Lab virtual machine to which the disk is attached.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/disks/{name}/attach") $qp $auth.query)
  let req_body = {"leasedByLabVmId": $leased_by_lab_vm_id} | compact
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

# Detach and break the lease of the disk attached to the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/disks/{name}/detach
# operationId: Disks_Detach
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-disks-detach create" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --leased-by-lab-vm-id: string # The resource ID of the Lab VM to which the disk is attached.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/disks/{name}/detach") $qp $auth.query)
  let req_body = {"leasedByLabVmId": $leased_by_lab_vm_id} | compact
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

# List environments in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments
# operationId: Environments_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=deploymentProperties)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/environments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete environment. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/environments/{name}") $qp $auth.query)
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

# Get environment.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=deploymentProperties)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/environments/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of environments. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_Update
# --properties shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of an environment. — shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/environments/{name}") $qp $auth.query)
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

# Create or replace an existing environment. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/environments/{name}
# operationId: Environments_CreateOrUpdate
# --properties shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-environments create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of an environment. — shape: {armTemplateDisplayName?: string, deploymentProperties?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<armTemplateDisplayName: string, createdByUser: string, deploymentProperties: record<armTemplateId: string, parameters: list>, provisioningState: string, resourceGroupId: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/environments/{name}") $qp $auth.query)
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

# List secrets in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets
# operationId: Secrets_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets list" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=value)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/secrets") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete secret.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets delete" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/secrets/{name}") $qp $auth.query)
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

# Get secret.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets get" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=value)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/secrets/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of secrets. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_Update
# --properties shape: {value?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a secret. — shape: {value?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/secrets/{name}") $qp $auth.query)
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

# Create or replace an existing secret. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/secrets/{name}
# operationId: Secrets_CreateOrUpdate
# --properties shape: {value?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-secrets create-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a secret. — shape: {value?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<provisioningState: string, uniqueIdentifier: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/secrets/{name}") $qp $auth.query)
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

# List service fabrics in a given user profile.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics
# operationId: ServiceFabrics_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics list-service-fabrics" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=applicableSchedule)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete service fabric. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics delete-service-fabrics" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{name}") $qp $auth.query)
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

# Get service fabric.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics get-service-fabrics" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=applicableSchedule)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<applicableSchedule: record<properties: record>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of service fabrics. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_Update
# --properties shape: {environmentId?: string, externalServiceFabricId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics update-service-fabrics" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a service fabric. — shape: {environmentId?: string, externalServiceFabricId?: string}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<applicableSchedule: record<properties: record>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{name}") $qp $auth.query)
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

# Create or replace an existing service fabric. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}
# operationId: ServiceFabrics_CreateOrUpdate
# --properties shape: {applicableSchedule?: record, environmentId?: string, externalServiceFabricId?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics create-service-fabrics-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a service fabric. — shape: {applicableSchedule?: record, environmentId?: string, externalServiceFabricId?: string}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<applicableSchedule: record<properties: record>, environmentId: string, externalServiceFabricId: string, provisioningState: string, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{name}") $qp $auth.query)
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

# Lists the applicable start/stop schedules, if any.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/listApplicableSchedules
# operationId: ServiceFabrics_ListApplicableSchedules
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-list-applicable-schedules list-service-fabrics" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<labVmsShutdown: record<properties: record>, labVmsStartup: record<properties: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{name}/listApplicableSchedules") $qp $auth.query)
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

# Start a service fabric. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/start
# operationId: ServiceFabrics_Start
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-start start-service-fabrics" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{name}/start") $qp $auth.query)
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

# Stop a service fabric This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{name}/stop
# operationId: ServiceFabrics_Stop
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-stop stop-service-fabrics" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{name}/stop") $qp $auth.query)
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

# List schedules in a given service fabric.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules
# operationId: ServiceFabricSchedules_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules list-service-fabric" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($service_fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceFabricName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), service_fabric_name: (encode-path-segment $service_fabric_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{service_fabric_name}/schedules") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules delete-service-fabric" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($service_fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceFabricName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), service_fabric_name: (encode-path-segment $service_fabric_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{service_fabric_name}/schedules/{name}") $qp $auth.query)
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

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules get-service-fabric" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($service_fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceFabricName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), service_fabric_name: (encode-path-segment $service_fabric_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{service_fabric_name}/schedules/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules update-service-fabric" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($service_fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceFabricName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), service_fabric_name: (encode-path-segment $service_fabric_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{service_fabric_name}/schedules/{name}") $qp $auth.query)
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

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}
# operationId: ServiceFabricSchedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules create-service-fabric-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($service_fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceFabricName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), service_fabric_name: (encode-path-segment $service_fabric_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{service_fabric_name}/schedules/{name}") $qp $auth.query)
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

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/users/{userName}/servicefabrics/{serviceFabricName}/schedules/{name}/execute
# operationId: ServiceFabricSchedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-users-servicefabrics-schedules-execute create-service-fabric" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  user_name: string
  service_fabric_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($user_name | is-empty) { error make --unspanned { msg: "path parameter 'userName' must be non-empty" } }
  if ($service_fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceFabricName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), user_name: (encode-path-segment $user_name), service_fabric_name: (encode-path-segment $service_fabric_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/users/{user_name}/servicefabrics/{service_fabric_name}/schedules/{name}/execute") $qp $auth.query)
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

# List virtual machines in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines
# operationId: VirtualMachines_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines list-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=artifacts,computeVm,networkInterface,applicableSchedule)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete virtual machine. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines delete-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}") $qp $auth.query)
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

# Get virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines get-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=artifacts,computeVm,networkInterface,applicableSchedule)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of virtual machines. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_Update
# --properties shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, ... (12 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines update-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a virtual machine. — shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, networkInterface?: record, ... (12 more fields)}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}") $qp $auth.query)
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

# Create or replace an existing virtual machine. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}
# operationId: VirtualMachines_CreateOrUpdate
# --properties shape: {allowClaim?: bool, applicableSchedule?: record, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, computeVm?: record, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, ... (14 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines create-virtual-machines-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a virtual machine. — shape: {allowClaim?: bool, applicableSchedule?: record, artifactDeploymentStatus?: record, artifacts?: list, computeId?: string, computeVm?: record, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, ... (14 more fields)}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowClaim: bool, applicableSchedule: record<properties: record>, artifactDeploymentStatus: record<artifactsApplied: int, deploymentStatus: string, totalArtifacts: int>, artifacts: list<record>, computeId: string, computeVm: record<dataDiskIds: list, dataDisks: list, networkInterfaceId: string, osDiskId: string, osType: string, statuses: list, vmSize: string>, createdByUser: string, createdByUserId: string, createdDate: string, customImageId: string, dataDiskParameters: list<record>, disallowPublicIpAddress: bool, environmentId: string, expirationDate: string, fqdn: string, galleryImageReference: record<offer: string, osType: string, publisher: string, sku: string, version: string>, isAuthenticationWithSshKey: bool, labSubnetName: string, labVirtualNetworkId: string, lastKnownPowerState: string, networkInterface: record<dnsName: string, privateIpAddress: string, publicIpAddress: string, publicIpAddressId: string, rdpAuthority: string, sharedPublicIpAddressConfiguration: record, sshAuthority: string, subnetId: string, virtualNetworkId: string>, notes: string, osType: string, ownerObjectId: string, ownerUserPrincipalName: string, password: string, planId: string, provisioningState: string, scheduleParameters: list<record>, size: string, sshKey: string, storageType: string, uniqueIdentifier: string, userName: string, virtualMachineCreationSource: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}") $qp $auth.query)
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

# Attach a new or existing data disk to virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/addDataDisk
# operationId: VirtualMachines_AddDataDisk
# --attachNewDataDiskOptions shape: {diskName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD"}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-add-data-disk create-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --attach-new-data-disk-options: record # Properties to attach new disk to the Virtual Machine. — shape: {diskName?: string, diskSizeGiB?: int, diskType?: "Standard"|"Premium"|"StandardSSD"}
  --existing-lab-disk-id: string # Specifies the existing lab disk id to attach to virtual machine.
  --host-caching: string@host-caching-completer # Caching option for a data disk (i.e. None, ReadOnly, ReadWrite).
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/addDataDisk") $qp $auth.query)
  let req_body = {"attachNewDataDiskOptions": $attach_new_data_disk_options, "existingLabDiskId": $existing_lab_disk_id, "hostCaching": $host_caching} | compact
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

# Apply artifacts to virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/applyArtifacts
# operationId: VirtualMachines_ApplyArtifacts
# --artifacts item shape: {artifactId?: string, artifactTitle?: string, deploymentStatusMessage?: string, installTime?: string, parameters?: list, status?: string, vmExtensionStatusMessage?: string}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-apply-artifacts create-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --artifacts: list # The list of artifacts to apply. — item shape: {artifactId?: string, artifactTitle?: string, deploymentStatusMessage?: string, installTime?: string, parameters?: list, status?: string, vmExtensionStatusMessage?: string}
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/applyArtifacts") $qp $auth.query)
  let req_body = {"artifacts": $artifacts} | compact
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

# Take ownership of an existing virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/claim
# operationId: VirtualMachines_Claim
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-claim create-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/claim") $qp $auth.query)
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

# Detach the specified disk from the virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/detachDataDisk
# operationId: VirtualMachines_DetachDataDisk
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-detach-data-disk create-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --existing-lab-disk-id: string # Specifies the disk resource ID to detach from virtual machine.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/detachDataDisk") $qp $auth.query)
  let req_body = {"existingLabDiskId": $existing_lab_disk_id} | compact
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

# Gets a string that represents the contents of the RDP file for the virtual machine
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/getRdpFileContents
# operationId: VirtualMachines_GetRdpFileContents
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-get-rdp-file-contents get-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<contents: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/getRdpFileContents") $qp $auth.query)
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

# Lists the applicable start/stop schedules, if any.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/listApplicableSchedules
# operationId: VirtualMachines_ListApplicableSchedules
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-list-applicable-schedules list-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<labVmsShutdown: record<properties: record>, labVmsStartup: record<properties: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/listApplicableSchedules") $qp $auth.query)
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

# Redeploy a virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/redeploy
# operationId: VirtualMachines_Redeploy
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-redeploy create-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/redeploy") $qp $auth.query)
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

# Resize Virtual Machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/resize
# operationId: VirtualMachines_Resize
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-resize resize-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --size: string # Specifies the size of the virtual machine.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/resize") $qp $auth.query)
  let req_body = {"size": $size} | compact
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

# Restart a virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/restart
# operationId: VirtualMachines_Restart
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-restart restart-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/restart") $qp $auth.query)
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

# Start a virtual machine. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/start
# operationId: VirtualMachines_Start
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-start start-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/start") $qp $auth.query)
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

# Stop a virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/stop
# operationId: VirtualMachines_Stop
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-stop stop-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/stop") $qp $auth.query)
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

# Transfers all data disks attached to the virtual machine to be owned by the current user. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/transferDisks
# operationId: VirtualMachines_TransferDisks
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-transfer-disks create-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/transferDisks") $qp $auth.query)
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

# Release ownership of an existing virtual machine This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{name}/unClaim
# operationId: VirtualMachines_UnClaim
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-un-claim create-virtual-machines" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{name}/unClaim") $qp $auth.query)
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

# List schedules in a given virtual machine.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules
# operationId: VirtualMachineSchedules_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules list-virtual-machine" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{virtual_machine_name}/schedules") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules delete-virtual-machine" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), virtual_machine_name: (encode-path-segment $virtual_machine_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{virtual_machine_name}/schedules/{name}") $qp $auth.query)
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

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules get-virtual-machine" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), virtual_machine_name: (encode-path-segment $virtual_machine_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{virtual_machine_name}/schedules/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules update-virtual-machine" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), virtual_machine_name: (encode-path-segment $virtual_machine_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{virtual_machine_name}/schedules/{name}") $qp $auth.query)
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

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}
# operationId: VirtualMachineSchedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules create-virtual-machine-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), virtual_machine_name: (encode-path-segment $virtual_machine_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{virtual_machine_name}/schedules/{name}") $qp $auth.query)
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

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualmachines/{virtualMachineName}/schedules/{name}/execute
# operationId: VirtualMachineSchedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualmachines-schedules-execute create-virtual-machine" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  virtual_machine_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), virtual_machine_name: (encode-path-segment $virtual_machine_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualmachines/{virtual_machine_name}/schedules/{name}/execute") $qp $auth.query)
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

# List virtual networks in a given lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks
# operationId: VirtualNetworks_List
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks list-virtual-networks" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=externalSubnets)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualnetworks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete virtual network. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks delete-virtual-networks" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualnetworks/{name}") $qp $auth.query)
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

# Get virtual network.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks get-virtual-networks" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($expand=externalSubnets)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualnetworks/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of virtual networks. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_Update
# --properties shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks update-virtual-networks" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a virtual network. — shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualnetworks/{name}") $qp $auth.query)
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

# Create or replace an existing virtual network. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{labName}/virtualnetworks/{name}
# operationId: VirtualNetworks_CreateOrUpdate
# --properties shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-virtualnetworks create-virtual-networks-or-update" [
  subscription_id: string
  resource_group_name: string
  lab_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a virtual network. — shape: {allowedSubnets?: list, description?: string, externalProviderResourceId?: string, subnetOverrides?: list}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<allowedSubnets: list<record>, createdDate: string, description: string, externalProviderResourceId: string, externalSubnets: list<record>, provisioningState: string, subnetOverrides: list<record>, uniqueIdentifier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($lab_name | is-empty) { error make --unspanned { msg: "path parameter 'labName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), lab_name: (encode-path-segment $lab_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{lab_name}/virtualnetworks/{name}") $qp $auth.query)
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

# Delete lab. This operation can take a while to complete.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs delete" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}") $qp $auth.query)
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

# Get lab.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs get" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=defaultStorageAccount)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of labs. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_Update
# --properties shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list<string>, mandatoryArtifactsResourceIdsWindows?: list<string>, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab. — shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list<string>, mandatoryArtifactsResourceIdsWindows?: list<string>, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}") $qp $auth.query)
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

# Create or replace an existing lab. This operation can take a while to complete.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}
# operationId: Labs_CreateOrUpdate
# --properties shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list<string>, mandatoryArtifactsResourceIdsWindows?: list<string>, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs create-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a lab. — shape: {announcement?: record, environmentPermission?: "Reader"|"Contributor", extendedProperties?: record, labStorageType?: "Standard"|"Premium"|"StandardSSD", mandatoryArtifactsResourceIdsLinux?: list<string>, mandatoryArtifactsResourceIdsWindows?: list<string>, premiumDataDisks?: "Disabled"|"Enabled", support?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<announcement: record<enabled: string, expirationDate: string, expired: bool, markdown: string, provisioningState: string, title: string, uniqueIdentifier: string>, artifactsStorageAccount: string, createdDate: string, defaultPremiumStorageAccount: string, defaultStorageAccount: string, environmentPermission: string, extendedProperties: record, labStorageType: string, loadBalancerId: string, mandatoryArtifactsResourceIdsLinux: list<string>, mandatoryArtifactsResourceIdsWindows: list<string>, networkSecurityGroupId: string, premiumDataDiskStorageAccount: string, premiumDataDisks: string, provisioningState: string, publicIpId: string, support: record<enabled: string, markdown: string>, uniqueIdentifier: string, vaultName: string, vmCreationResourceGroup: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}") $qp $auth.query)
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

# Claim a random claimable virtual machine in the lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/claimAnyVm
# operationId: Labs_ClaimAnyVm
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-claim-any-vm create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}/claimAnyVm") $qp $auth.query)
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

# Create virtual machines in a lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/createEnvironment
# operationId: Labs_CreateEnvironment
# --properties shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, bulkCreationParameters?: record, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, ... (13 more fields)}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-create-environment create" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --location: string # The location of the new virtual machine or environment
  --body-name: string # The name of the virtual machine or environment
  --properties: record # Properties for virtual machine creation. — shape: {allowClaim?: bool, artifactDeploymentStatus?: record, artifacts?: list, bulkCreationParameters?: record, computeId?: string, createdByUser?: string, createdByUserId?: string, createdDate?: string, customImageId?: string, dataDiskParameters?: list, disallowPublicIpAddress?: bool, environmentId?: string, expirationDate?: string, fqdn?: string, galleryImageReference?: record, isAuthenticationWithSshKey?: bool, labSubnetName?: string, labVirtualNetworkId?: string, lastKnownPowerState?: string, ... (13 more fields)}
  --tags: record # The tags of the resource.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}/createEnvironment") $qp $auth.query)
  let req_body = {"location": $location, "name": $body_name, "properties": $properties, "tags": $tags} | compact
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

# Exports the lab resource usage into a storage account This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/exportResourceUsage
# operationId: Labs_ExportResourceUsage
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-export-resource-usage export" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --blob-storage-absolute-sas-uri: string # The blob storage absolute sas uri with write permission to the container which the usage data needs to be uploaded to.
  --usage-start-date: string # The start time of the usage. If not provided, usage will be reported since the beginning of data collection. (format: date-time)
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}/exportResourceUsage") $qp $auth.query)
  let req_body = {"blobStorageAbsoluteSasUri": $blob_storage_absolute_sas_uri, "usageStartDate": $usage_start_date} | compact
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

# Generate a URI for uploading custom disk images to a Lab.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/generateUploadUri
# operationId: Labs_GenerateUploadUri
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-generate-upload-uri generate" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --blob-name: string # The blob name of the upload URI.
]: any -> record<uploadUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}/generateUploadUri") $qp $auth.query)
  let req_body = {"blobName": $blob_name} | compact
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

# Import a virtual machine into a different lab. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/importVirtualMachine
# operationId: Labs_ImportVirtualMachine
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-import-virtual-machine import" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --destination-virtual-machine-name: string # The name of the virtual machine in the destination lab
  --source-virtual-machine-resource-id: string # The full resource ID of the virtual machine to be imported.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}/importVirtualMachine") $qp $auth.query)
  let req_body = {"destinationVirtualMachineName": $destination_virtual_machine_name, "sourceVirtualMachineResourceId": $source_virtual_machine_resource_id} | compact
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

# List disk images available for custom image creation.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/labs/{name}/listVhds
# operationId: Labs_ListVhds
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-labs-list-vhds list" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/labs/{name}/listVhds") $qp $auth.query)
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

# List schedules in a resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules
# operationId: GlobalSchedules_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules list-global" [
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
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --filter: string # The filter to apply to the operation. Example: '$filter=contains(name,'myName')
  --top: int # The maximum number of resources to return from the operation. Example: '$top=10' (format: int32)
  --orderby: string # The ordering expression for the results, using OData notation. Example: '$orderby=name desc'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/schedules") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "$filter": $filter, "$top": $top, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete schedule.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_Delete
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules delete-global" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/schedules/{name}") $qp $auth.query)
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

# Get schedule.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_Get
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules get-global" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Specify the $expand query. Example: 'properties($select=status)'
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/schedules/{name}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$expand": $expand, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows modifying tags of schedules. All other properties will be ignored.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_Update
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules update-global" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/schedules/{name}") $qp $auth.query)
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

# Create or replace an existing schedule.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}
# operationId: GlobalSchedules_CreateOrUpdate
# --properties shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules create-global-or-update" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  properties: record # Properties of a schedule. — shape: {dailyRecurrence?: record, hourlyRecurrence?: record, notificationSettings?: record, status?: "Enabled"|"Disabled", targetResourceId?: string, taskType?: string, timeZoneId?: string, weeklyRecurrence?: record}
  --location: string # The location of the resource.
  --tags: record # The tags of the resource.
]: any -> record<properties: record<createdDate: string, dailyRecurrence: record<time: string>, hourlyRecurrence: record<minute: int>, notificationSettings: record<emailRecipient: string, notificationLocale: string, status: string, timeInMinutes: int, webhookUrl: string>, provisioningState: string, status: string, targetResourceId: string, taskType: string, timeZoneId: string, uniqueIdentifier: string, weeklyRecurrence: record<time: string, weekdays: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/schedules/{name}") $qp $auth.query)
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

# Execute a schedule. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/execute
# operationId: GlobalSchedules_Execute
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules-execute create-global" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/schedules/{name}/execute") $qp $auth.query)
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

# Updates a schedule's target resource Id. This operation can take a while to complete.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DevTestLab/schedules/{name}/retarget
# operationId: GlobalSchedules_Retarget
export def "subscriptions-resource-groups-providers-microsoft-dev-test-lab-schedules-retarget create-global" [
  subscription_id: string
  resource_group_name: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version. (default: 2018-09-15)
  --current-resource-id: string # The resource Id of the virtual machine on which the schedule operates
  --target-resource-id: string # The resource Id of the virtual machine that the schedule should be retargeted to
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), name: (encode-path-segment $name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.DevTestLab/schedules/{name}/retarget") $qp $auth.query)
  let req_body = {"currentResourceId": $current_resource_id, "targetResourceId": $target_resource_id} | compact
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
