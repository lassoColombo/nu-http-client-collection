# Auto-generated client for TimeSeriesInsightsClient v2018-11-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/timeseriesinsights/2018-11-01-preview/swagger.json
# Auth: --token flag or $env.TIMESERIESINSIGHTSCLIENT_TOKEN

const BASE_URL = "https://{environmentFqdn}"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TIMESERIESINSIGHTSCLIENT_TOKEN | default "" }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://{environmentFqdn}"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "availability list-get" } } | get name | first)
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

# Returns the time range and distribution of event count over the event timestamp ($ts). This API can be used to provide landing experience of navigating to the environment.
#
# GET /availability
# operationId: Query_GetAvailability
export def "availability list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --store-type: string # For the environments with warm store enabled, the query can be executed either on the 'WarmStore' or 'ColdStore'. This parameter in the query defines which store the query should be executed on. If not defined, the query will be executed on the cold store.
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
]: nothing -> record<availability: record<distribution: any, intervalSize: string, range: record<from: string, to: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "storeType" $store_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/availability" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version, "storeType": $store_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns environment event schema for a given search span. Event schema is a set of property definitions. Event schema may not be contain all persisted properties when there are too many properties.
#
# POST /eventSchema
# operationId: Query_GetEventSchema
# --searchSpan shape: {from: string, to: string}
export def "event-schema list-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --store-type: string # For the environments with warm store enabled, the query can be executed either on the 'WarmStore' or 'ColdStore'. This parameter in the query defines which store the query should be executed on. If not defined, the query will be executed on the cold store.
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  search_span: record # The range of time. Cannot be null or negative. — shape: {from: string, to: string}
]: any -> record<properties: table<name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "storeType" $store_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eventSchema" $qp $auth.query)
  let req_body = {"searchSpan": $search_span} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version, "storeType": $store_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns time series hierarchies definitions in pages.
#
# GET /timeseries/hierarchies
# operationId: TimeSeriesHierarchies_Get
export def "timeseries-hierarchies get-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-continuation: string # Continuation token from previous page of results to retrieve the next page of the results in calls that support pagination. To get the first page results, specify null continuation token as parameter value. Returned continuation token is null if all results have been returned, and there is no next page of results.
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
]: nothing -> record<continuationToken: string, hierarchies: table<id: string, name: string, source: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/hierarchies" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-continuation": $x_ms_continuation, "x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Executes a batch get, create, update, delete operation on multiple time series hierarchy definitions.
#
# POST /timeseries/hierarchies/$batch
# operationId: TimeSeriesHierarchies_ExecuteBatch
# --delete shape: {hierarchyIds?: list<string>, names?: list<string>}
# --get shape: {hierarchyIds?: list<string>, names?: list<string>}
# --put item shape: {id?: string, name: string, source: record}
export def "timeseries-hierarchies-batch create-time-series-execute-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  --delete: record # Request to get or delete multiple time series hierarchies. Exactly one of "hierarchyIds" or "names" must be set. — shape: {hierarchyIds?: list<string>, names?: list<string>}
  --body-get: record # Request to get or delete multiple time series hierarchies. Exactly one of "hierarchyIds" or "names" must be set. — shape: {hierarchyIds?: list<string>, names?: list<string>}
  --put: list # "put" should be set while creating or updating hierarchies. — item shape: {id?: string, name: string, source: record}
]: any -> record<delete: table<code: string, details: list, innerError: any, message: string, target: string>, get: table<error: record, hierarchy: record>, put: table<error: record, hierarchy: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/hierarchies/$batch" $qp $auth.query)
  let req_body = {"delete": $delete, "get": $body_get, "put": $put} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets time series instances in pages.
#
# GET /timeseries/instances
# operationId: TimeSeriesInstances_Get
export def "timeseries-instances get-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-continuation: string # Continuation token from previous page of results to retrieve the next page of the results in calls that support pagination. To get the first page results, specify null continuation token as parameter value. Returned continuation token is null if all results have been returned, and there is no next page of results.
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
]: nothing -> record<continuationToken: string, instances: table<description: string, hierarchyIds: list, instanceFields: record, name: string, timeSeriesId: list, typeId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/instances" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-continuation": $x_ms_continuation, "x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Executes a batch get, create, update, delete operation on multiple time series instances.
#
# POST /timeseries/instances/$batch
# operationId: TimeSeriesInstances_ExecuteBatch
# --delete shape: {names?: list<string>, timeSeriesIds?: list}
# --get shape: {names?: list<string>, timeSeriesIds?: list}
# --put item shape: {description?: string, hierarchyIds?: list<string>, instanceFields?: record, name?: string, timeSeriesId: list, typeId: string}
# --update item shape: {description?: string, hierarchyIds?: list<string>, instanceFields?: record, name?: string, timeSeriesId: list, typeId: string}
export def "timeseries-instances-batch create-time-series-execute-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  --delete: record # Request to get or delete instances by time series IDs or time series names. Exactly one of "timeSeriesIds" or "names" must be set. — shape: {names?: list<string>, timeSeriesIds?: list}
  --body-get: record # Request to get or delete instances by time series IDs or time series names. Exactly one of "timeSeriesIds" or "names" must be set. — shape: {names?: list<string>, timeSeriesIds?: list}
  --put: list # Time series instances to be created or updated. — item shape: {description?: string, hierarchyIds?: list<string>, instanceFields?: record, name?: string, timeSeriesId: list, typeId: string}
  --update: list # Time series instances to be updated onlRequest to perform a single operation on a batch of instances. y. If instance does not exist, an error is returned. — item shape: {description?: string, hierarchyIds?: list<string>, instanceFields?: record, name?: string, timeSeriesId: list, typeId: string}
]: any -> record<delete: table<code: string, details: list, innerError: any, message: string, target: string>, get: table<error: record, instance: record>, put: table<error: record, instance: record>, update: table<error: record, instance: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/instances/$batch" $qp $auth.query)
  let req_body = {"delete": $delete, "get": $body_get, "put": $put, "update": $update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Partial list of hits on search for time series instances based on instance attributes.
#
# POST /timeseries/instances/search
# operationId: TimeSeriesInstances_Search
# --hierarchies shape: {expand?: record, pageSize?: int, sort?: record}
# --instances shape: {highlights?: bool, pageSize?: int, recursive?: bool, sort?: record}
export def "timeseries-instances-search list-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-continuation: string # Continuation token from previous page of results to retrieve the next page of the results in calls that support pagination. To get the first page results, specify null continuation token as parameter value. Returned continuation token is null if all results have been returned, and there is no next page of results.
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  --hierarchies: record # Parameter of how to return time series instance hierarchies by search instances call. — shape: {expand?: record, pageSize?: int, sort?: record}
  --instances: record # Parameters of how to return time series instances by search instances call. — shape: {highlights?: bool, pageSize?: int, recursive?: bool, sort?: record}
  --path: list<string> # Filter on hierarchy path of time series instances. Path is represented as array of string path segments. First element should be hierarchy name. Example: ["Location", "California"]. Optional, case sensitive, never empty and can be null.
  search_string: string # Query search string that will be matched to the attributes of time series instances. Example: "floor 100". Case-insensitive, must be present, but can be empty string.
]: any -> record<hierarchyNodes: record<continuationToken: string, hitCount: int, hits: list<record>>, instances: record<continuationToken: string, hitCount: int, hits: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/instances/search" $qp $auth.query)
  let req_body = {"hierarchies": $hierarchies, "instances": $instances, "path": $path, "searchString": $search_string} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-continuation": $x_ms_continuation, "x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Suggests keywords based on time series instance attributes to be later used in Search Instances.
#
# POST /timeseries/instances/suggest
# operationId: TimeSeriesInstances_Suggest
export def "timeseries-instances-suggest create-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  search_string: string # Search string for which suggestions are required. Empty is allowed, but not null.
  --take: int # Maximum number of suggestions expected in the result. Defaults to 10 when not set. (format: int32)
]: any -> record<suggestions: table<highlightedSearchString: string, searchString: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/instances/suggest" $qp $auth.query)
  let req_body = {"searchString": $search_string, "take": $take} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns the model settings which includes model display name, Time Series ID properties and default type ID. Every pay-as-you-go environment has a model that is automatically created.
#
# GET /timeseries/modelSettings
# operationId: ModelSettings_Get
export def "timeseries-model-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
]: nothing -> record<modelSettings: record<defaultTypeId: string, name: string, timeSeriesIdProperties: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/modelSettings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates time series model settings - either the model name or default type ID.
#
# PATCH /timeseries/modelSettings
# operationId: ModelSettings_Update
export def "timeseries-model-settings update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  --default-type-id: string # Default type id of the model that new instances will automatically belong to. (format: uuid)
  --name: string # Model display name which is shown in the UX and mutable by the user. Initial value is "DefaultModel".
]: any -> record<modelSettings: record<defaultTypeId: string, name: string, timeSeriesIdProperties: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/modelSettings" $qp $auth.query)
  let req_body = {"defaultTypeId": $default_type_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Executes Time Series Query in pages of results - Get Events, Get Series or Aggregate Series.
#
# POST /timeseries/query
# operationId: Query_Execute
# --aggregateSeries shape: {filter?: record, inlineVariables?: record, interval: string, projectedVariables?: list<string>, searchSpan: record, timeSeriesId: list}
# --getEvents shape: {filter?: record, projectedProperties?: list, searchSpan: record, take?: int, timeSeriesId: list}
# --getSeries shape: {filter?: record, inlineVariables?: record, projectedVariables?: list<string>, searchSpan: record, take?: int, timeSeriesId: list}
export def "timeseries-query list-execute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --store-type: string # For the environments with warm store enabled, the query can be executed either on the 'WarmStore' or 'ColdStore'. This parameter in the query defines which store the query should be executed on. If not defined, the query will be executed on the cold store.
  --x-ms-continuation: string # Continuation token from previous page of results to retrieve the next page of the results in calls that support pagination. To get the first page results, specify null continuation token as parameter value. Returned continuation token is null if all results have been returned, and there is no next page of results.
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  --aggregate-series: record # Aggregate Series query. Allows to calculate an aggregated time series from events for a given Time Series ID and search span. — shape: {filter?: record, inlineVariables?: record, interval: string, projectedVariables?: list<string>, searchSpan: record, timeSeriesId: list}
  --get-events: record # Get Events query. Allows to retrieve raw events for a given Time Series ID and search span. — shape: {filter?: record, projectedProperties?: list, searchSpan: record, take?: int, timeSeriesId: list}
  --get-series: record # Get Series query. Allows to retrieve time series of calculated variable values from events for a given Time Series ID and search span. — shape: {filter?: record, inlineVariables?: record, projectedVariables?: list<string>, searchSpan: record, take?: int, timeSeriesId: list}
]: any -> record<continuationToken: string, progress: float, properties: table<name: string, type: string, values: list>, timestamps: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "storeType" $store_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/query" $qp $auth.query)
  let req_body = {"aggregateSeries": $aggregate_series, "getEvents": $get_events, "getSeries": $get_series} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-continuation": $x_ms_continuation, "x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version, "storeType": $store_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets time series types in pages.
#
# GET /timeseries/types
# operationId: TimeSeriesTypes_Get
export def "timeseries-types get-time-series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-continuation: string # Continuation token from previous page of results to retrieve the next page of the results in calls that support pagination. To get the first page results, specify null continuation token as parameter value. Returned continuation token is null if all results have been returned, and there is no next page of results.
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
]: nothing -> record<continuationToken: string, types: table<description: string, id: string, name: string, variables: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/types" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-continuation": $x_ms_continuation, "x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Executes a batch get, create, update, delete operation on multiple time series types.
#
# POST /timeseries/types/$batch
# operationId: TimeSeriesTypes_ExecuteBatch
# --delete shape: {names?: list<string>, typeIds?: list<string>}
# --get shape: {names?: list<string>, typeIds?: list<string>}
# --put item shape: {description?: string, id?: string, name: string, variables: any}
export def "timeseries-types-batch create-time-series-execute-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. Currently supported version is "2018-11-01-preview". (default: 2018-11-01-preview)
  --x-ms-client-request-id: string # Optional client request ID. Service records this value. Allows the service to trace operation across services, and allows the customer to contact support regarding a particular request.
  --x-ms-client-session-id: string # Optional client session ID. Service records this value. Allows the service to trace a group of related operations across services, and allows the customer to contact support regarding a particular group of requests.
  --delete: record # Request to get or delete time series types by IDs or type names. Exactly one of "typeIds" or "names" must be set. — shape: {names?: list<string>, typeIds?: list<string>}
  --body-get: record # Request to get or delete time series types by IDs or type names. Exactly one of "typeIds" or "names" must be set. — shape: {names?: list<string>, typeIds?: list<string>}
  --put: list # Definition of what time series types to update or create. — item shape: {description?: string, id?: string, name: string, variables: any}
]: any -> record<delete: table<code: string, details: list, innerError: any, message: string, target: string>, get: table<error: record, timeSeriesType: record>, put: table<error: record, timeSeriesType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/timeseries/types/$batch" $qp $auth.query)
  let req_body = {"delete": $delete, "get": $body_get, "put": $put} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-ms-client-request-id": $x_ms_client_request_id, "x-ms-client-session-id": $x_ms_client_session_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
