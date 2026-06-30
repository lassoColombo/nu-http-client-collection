# Auto-generated client for ApiManagementClient v2019-12-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/apimanagement-apimreports/2019-12-01-preview/swagger.json
# Auth: --token flag or $env.APIMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o APIMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-api list" } } | get name | first)
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

# Lists report records by API.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/byApi
# operationId: Reports_ListByApi
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-api list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # The filter to apply on the operation.
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --orderby: string # OData order by query option.
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, nextLink: string, value: table<apiId: string, apiRegion: string, apiTimeAvg: float, apiTimeMax: float, apiTimeMin: float, bandwidth: int, cacheHitCount: int, cacheMissCount: int, callCountBlocked: int, callCountFailed: int, callCountOther: int, callCountSuccess: int, callCountTotal: int, country: string, interval: string, name: string, operationId: string, productId: string, region: string, serviceTimeAvg: float, serviceTimeMax: float, serviceTimeMin: float, subscriptionId: string, timestamp: string, userId: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/byApi") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists report records by geography.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/byGeo
# operationId: Reports_ListByGeo
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-geo list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| timestamp | filter | ge, le | | | country | select | | | | region | select | | | | zip | select | | | | apiRegion | filter | eq | | | userId | filter | eq | | | productId | filter | eq | | | subscriptionId | filter | eq | | | apiId | filter | eq | | | operationId | filter | eq | | | callCountSuccess | select | | | | callCountBlocked | select | | | | callCountFailed | select | | | | callCountOther | select | | | | bandwidth | select, orderBy | | | | cacheHitsCount | select | | | | cacheMissCount | select | | | | apiTimeAvg | select | | | | apiTimeMin | select | | | | apiTimeMax | select | | | | serviceTimeAvg | select | | | | serviceTimeMin | select | | | | serviceTimeMax | select | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, nextLink: string, value: table<apiId: string, apiRegion: string, apiTimeAvg: float, apiTimeMax: float, apiTimeMin: float, bandwidth: int, cacheHitCount: int, cacheMissCount: int, callCountBlocked: int, callCountFailed: int, callCountOther: int, callCountSuccess: int, callCountTotal: int, country: string, interval: string, name: string, operationId: string, productId: string, region: string, serviceTimeAvg: float, serviceTimeMax: float, serviceTimeMin: float, subscriptionId: string, timestamp: string, userId: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/byGeo") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists report records by API Operations.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/byOperation
# operationId: Reports_ListByOperation
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-operation list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| timestamp | filter | ge, le | | | displayName | select, orderBy | | | | apiRegion | filter | eq | | | userId | filter | eq | | | productId | filter | eq | | | subscriptionId | filter | eq | | | apiId | filter | eq | | | operationId | select, filter | eq | | | callCountSuccess | select, orderBy | | | | callCountBlocked | select, orderBy | | | | callCountFailed | select, orderBy | | | | callCountOther | select, orderBy | | | | callCountTotal | select, orderBy | | | | bandwidth | select, orderBy | | | | cacheHitsCount | select | | | | cacheMissCount | select | | | | apiTimeAvg | select, orderBy | | | | apiTimeMin | select | | | | apiTimeMax | select | | | | serviceTimeAvg | select | | | | serviceTimeMin | select | | | | serviceTimeMax | select | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --orderby: string # OData order by query option.
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, nextLink: string, value: table<apiId: string, apiRegion: string, apiTimeAvg: float, apiTimeMax: float, apiTimeMin: float, bandwidth: int, cacheHitCount: int, cacheMissCount: int, callCountBlocked: int, callCountFailed: int, callCountOther: int, callCountSuccess: int, callCountTotal: int, country: string, interval: string, name: string, operationId: string, productId: string, region: string, serviceTimeAvg: float, serviceTimeMax: float, serviceTimeMin: float, subscriptionId: string, timestamp: string, userId: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/byOperation") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists report records by Product.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/byProduct
# operationId: Reports_ListByProduct
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-product list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| timestamp | filter | ge, le | | | displayName | select, orderBy | | | | apiRegion | filter | eq | | | userId | filter | eq | | | productId | select, filter | eq | | | subscriptionId | filter | eq | | | callCountSuccess | select, orderBy | | | | callCountBlocked | select, orderBy | | | | callCountFailed | select, orderBy | | | | callCountOther | select, orderBy | | | | callCountTotal | select, orderBy | | | | bandwidth | select, orderBy | | | | cacheHitsCount | select | | | | cacheMissCount | select | | | | apiTimeAvg | select, orderBy | | | | apiTimeMin | select | | | | apiTimeMax | select | | | | serviceTimeAvg | select | | | | serviceTimeMin | select | | | | serviceTimeMax | select | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --orderby: string # OData order by query option.
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, nextLink: string, value: table<apiId: string, apiRegion: string, apiTimeAvg: float, apiTimeMax: float, apiTimeMin: float, bandwidth: int, cacheHitCount: int, cacheMissCount: int, callCountBlocked: int, callCountFailed: int, callCountOther: int, callCountSuccess: int, callCountTotal: int, country: string, interval: string, name: string, operationId: string, productId: string, region: string, serviceTimeAvg: float, serviceTimeMax: float, serviceTimeMin: float, subscriptionId: string, timestamp: string, userId: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/byProduct") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists report records by Request.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/byRequest
# operationId: Reports_ListByRequest
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-request list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| timestamp | filter | ge, le | | | apiId | filter | eq | | | operationId | filter | eq | | | productId | filter | eq | | | userId | filter | eq | | | apiRegion | filter | eq | | | subscriptionId | filter | eq | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, value: table<apiId: string, apiRegion: string, apiTime: float, backendResponseCode: string, cache: string, ipAddress: string, method: string, operationId: string, productId: string, requestId: string, requestSize: int, responseCode: int, responseSize: int, serviceTime: float, subscriptionId: string, timestamp: string, url: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/byRequest") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists report records by subscription.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/bySubscription
# operationId: Reports_ListBySubscription
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-subscription list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| timestamp | filter | ge, le | | | displayName | select, orderBy | | | | apiRegion | filter | eq | | | userId | select, filter | eq | | | productId | select, filter | eq | | | subscriptionId | select, filter | eq | | | callCountSuccess | select, orderBy | | | | callCountBlocked | select, orderBy | | | | callCountFailed | select, orderBy | | | | callCountOther | select, orderBy | | | | callCountTotal | select, orderBy | | | | bandwidth | select, orderBy | | | | cacheHitsCount | select | | | | cacheMissCount | select | | | | apiTimeAvg | select, orderBy | | | | apiTimeMin | select | | | | apiTimeMax | select | | | | serviceTimeAvg | select | | | | serviceTimeMin | select | | | | serviceTimeMax | select | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --orderby: string # OData order by query option.
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, nextLink: string, value: table<apiId: string, apiRegion: string, apiTimeAvg: float, apiTimeMax: float, apiTimeMin: float, bandwidth: int, cacheHitCount: int, cacheMissCount: int, callCountBlocked: int, callCountFailed: int, callCountOther: int, callCountSuccess: int, callCountTotal: int, country: string, interval: string, name: string, operationId: string, productId: string, region: string, serviceTimeAvg: float, serviceTimeMax: float, serviceTimeMin: float, subscriptionId: string, timestamp: string, userId: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/bySubscription") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists report records by Time.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/byTime
# operationId: Reports_ListByTime
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-time list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| timestamp | filter, select | ge, le | | | interval | select | | | | apiRegion | filter | eq | | | userId | filter | eq | | | productId | filter | eq | | | subscriptionId | filter | eq | | | apiId | filter | eq | | | operationId | filter | eq | | | callCountSuccess | select | | | | callCountBlocked | select | | | | callCountFailed | select | | | | callCountOther | select | | | | bandwidth | select, orderBy | | | | cacheHitsCount | select | | | | cacheMissCount | select | | | | apiTimeAvg | select | | | | apiTimeMin | select | | | | apiTimeMax | select | | | | serviceTimeAvg | select | | | | serviceTimeMin | select | | | | serviceTimeMax | select | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --orderby: string # OData order by query option.
  --interval: string # By time interval. Interval must be multiple of 15 minutes and may not be zero. The value should be in ISO 8601 format (http://en.wikipedia.org/wiki/ISO_8601#Durations).This code can be used to convert TimeSpan to a valid interval string: XmlConvert.ToString(new TimeSpan(hours, minutes, seconds)). (format: duration)
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, nextLink: string, value: table<apiId: string, apiRegion: string, apiTimeAvg: float, apiTimeMax: float, apiTimeMin: float, bandwidth: int, cacheHitCount: int, cacheMissCount: int, callCountBlocked: int, callCountFailed: int, callCountOther: int, callCountSuccess: int, callCountTotal: int, country: string, interval: string, name: string, operationId: string, productId: string, region: string, serviceTimeAvg: float, serviceTimeMax: float, serviceTimeMin: float, subscriptionId: string, timestamp: string, userId: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/byTime") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "$orderby": $orderby, "interval": $interval, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists report records by User.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/reports/byUser
# operationId: Reports_ListByUser
export def "subscriptions-resource-groups-providers-microsoft-api-management-service-reports-by-user list" [
  subscription_id: string
  resource_group_name: string
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
  --filter: string # | Field | Usage | Supported operators | Supported functions ||-------------|-------------|-------------|-------------|| timestamp | filter | ge, le | | | displayName | select, orderBy | | | | userId | select, filter | eq | | | apiRegion | filter | eq | | | productId | filter | eq | | | subscriptionId | filter | eq | | | apiId | filter | eq | | | operationId | filter | eq | | | callCountSuccess | select, orderBy | | | | callCountBlocked | select, orderBy | | | | callCountFailed | select, orderBy | | | | callCountOther | select, orderBy | | | | callCountTotal | select, orderBy | | | | bandwidth | select, orderBy | | | | cacheHitsCount | select | | | | cacheMissCount | select | | | | apiTimeAvg | select, orderBy | | | | apiTimeMin | select | | | | apiTimeMax | select | | | | serviceTimeAvg | select | | | | serviceTimeMin | select | | | | serviceTimeMax | select | | |
  --top: int # Number of records to return. (format: int32)
  --skip: int # Number of records to skip. (format: int32)
  --orderby: string # OData order by query option.
  --api-version: string # Version of the API to be used with the client request.
]: nothing -> record<count: int, nextLink: string, value: table<apiId: string, apiRegion: string, apiTimeAvg: float, apiTimeMax: float, apiTimeMin: float, bandwidth: int, cacheHitCount: int, cacheMissCount: int, callCountBlocked: int, callCountFailed: int, callCountOther: int, callCountSuccess: int, callCountTotal: int, country: string, interval: string, name: string, operationId: string, productId: string, region: string, serviceTimeAvg: float, serviceTimeMax: float, serviceTimeMin: float, subscriptionId: string, timestamp: string, userId: string, zip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($service_name | is-empty) { error make --unspanned { msg: "path parameter 'serviceName' must be non-empty" } }
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), service_name: (encode-path-segment $service_name)} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{service_name}/reports/byUser") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "$orderby": $orderby, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
