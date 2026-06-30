# Auto-generated client for Application Insights Data Plane v2018-04-20
# Source: https://api.apis.guru/v2/specs/azure.com/applicationinsights-swagger/2018-04-20/swagger.json
# Auth: --token flag or $env.APPLICATION_INSIGHTS_DATA_PLANE_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o APPLICATION_INSIGHTS_DATA_PLANE_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resourcegroups-providers-microsoft-insights-components-events-metadata get-odata-metadata" } } | get name | first)
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

# Get OData metadata
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Insights/components/{applicationName}/events/$metadata
# operationId: Events_GetOdataMetadata
export def "subscriptions-resourcegroups-providers-microsoft-insights-components-events-metadata get-odata-metadata" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "apiVersion" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Insights/components/{application_name}/events/$metadata") $qp $auth.query)
  let accept_val = "application/xml;charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiVersion": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Execute OData query
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Insights/components/{applicationName}/events/{eventType}
# operationId: Events_GetByType
export def "subscriptions-resourcegroups-providers-microsoft-insights-components-events get-by-type" [
  subscription_id: string
  resource_group_name: string
  application_name: string
  event_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timespan: string # Optional. The timespan over which to retrieve events. This is an ISO8601 time period value. This timespan is applied in addition to any that are specified in the Odata expression.
  --filter: string # An expression used to filter the returned events
  --search: string # A free-text search expression to match for whether a particular event should be returned
  --orderby: string # A comma-separated list of properties with \"asc\" (the default) or \"desc\" to control the order of returned events
  --select: string # Limits the properties to just those requested on each returned event
  --skip: int # The number of items to skip over before returning events (format: int32)
  --top: int # The number of events to return (format: int32)
  --format: string # Format for the returned events
  --count: oneof<nothing, bool> # Request a count of matching items included with the returned events
  --apply: string # An expression used for aggregation over returned events
  --api-version: string # Client API version.
]: nothing -> record<_ai_messages: table<additionalProperties: record, code: string, details: list, innererror: any, message: string>, _odata_context: string, value: table<ai: record, application: record, client: record, cloud: record, count: int, customDimensions: record, customMeasurements: record, id: string, operation: record, session: record, timestamp: string, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  if ($event_type | is-empty) { error make --unspanned { msg: "path parameter 'eventType' must be non-empty" } }
  let qp = [(serialize-qp "timespan" $timespan "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$format" $format "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$apply" $apply "scalar") (serialize-qp "apiVersion" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_name: (encode-path-segment $application_name), event_type: (encode-path-segment $event_type)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Insights/components/{application_name}/events/{event_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timespan": $timespan, "$filter": $filter, "$search": $search, "$orderby": $orderby, "$select": $select, "$skip": $skip, "$top": $top, "$format": $format, "$count": $count, "$apply": $apply, "apiVersion": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an event
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Insights/components/{applicationName}/events/{eventType}/{eventId}
# operationId: Events_Get
export def "subscriptions-resourcegroups-providers-microsoft-insights-components-events get" [
  subscription_id: string
  resource_group_name: string
  application_name: string
  event_type: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timespan: string # Optional. The timespan over which to retrieve events. This is an ISO8601 time period value. This timespan is applied in addition to any that are specified in the Odata expression.
  --api-version: string # Client API version.
]: nothing -> record<_ai_messages: table<additionalProperties: record, code: string, details: list, innererror: any, message: string>, _odata_context: string, value: table<ai: record, application: record, client: record, cloud: record, count: int, customDimensions: record, customMeasurements: record, id: string, operation: record, session: record, timestamp: string, type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  if ($event_type | is-empty) { error make --unspanned { msg: "path parameter 'eventType' must be non-empty" } }
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "timespan" $timespan "scalar") (serialize-qp "apiVersion" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_name: (encode-path-segment $application_name), event_type: (encode-path-segment $event_type), event_id: (encode-path-segment $event_id)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Insights/components/{application_name}/events/{event_type}/{event_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timespan": $timespan, "apiVersion": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve metric metadata
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Insights/components/{applicationName}/metrics/metadata
# operationId: Metrics_GetMetadata
export def "subscriptions-resourcegroups-providers-microsoft-insights-components-metrics-metadata get" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "apiVersion" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Insights/components/{application_name}/metrics/metadata") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiVersion": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve metric data
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Insights/components/{applicationName}/metrics/{metricId}
# operationId: Metrics_Get
export def "subscriptions-resourcegroups-providers-microsoft-insights-components-metrics get" [
  subscription_id: string
  resource_group_name: string
  application_name: string
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timespan: string # The timespan over which to retrieve metric values. This is an ISO8601 time period value. If timespan is omitted, a default time range of `PT12H` ("last 12 hours") is used. The actual timespan that is queried may be adjusted by the server based. In all cases, the actual time span used for the query is included in the response.
  --interval: string # The time interval to use when retrieving metric values. This is an ISO8601 duration. If interval is omitted, the metric value is aggregated across the entire timespan. If interval is supplied, the server may adjust the interval to a more appropriate size based on the timespan used for the query. In all cases, the actual interval used for the query is included in the response. (format: duration)
  --aggregation: list<string> # The aggregation to use when computing the metric values. To retrieve more than one aggregation at a time, separate them with a comma. If no aggregation is specified, then the default aggregation for the metric is used.
  --segment: list<string> # The name of the dimension to segment the metric values by. This dimension must be applicable to the metric you are retrieving. To segment by more than one dimension at a time, separate them with a comma (,). In this case, the metric data will be segmented in the order the dimensions are listed in the parameter.
  --top: int # The number of segments to return. This value is only valid when segment is specified. (format: int32)
  --orderby: string # The aggregation function and direction to sort the segments by. This value is only valid when segment is specified.
  --filter: string # An expression used to filter the results. This value should be a valid OData filter expression where the keys of each clause should be applicable dimensions for the metric you are retrieving.
  --api-version: string # Client API version.
]: nothing -> record<value: record<end: string, interval: string, segments: list<record>, start: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  if ($metric_id | is-empty) { error make --unspanned { msg: "path parameter 'metricId' must be non-empty" } }
  let qp = [(serialize-qp "timespan" $timespan "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "aggregation" $aggregation "csv") (serialize-qp "segment" $segment "csv") (serialize-qp "top" $top "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "apiVersion" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_name: (encode-path-segment $application_name), metric_id: (encode-path-segment $metric_id)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Insights/components/{application_name}/metrics/{metric_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timespan": $timespan, "interval": $interval, "aggregation": $aggregation, "segment": $segment, "top": $top, "orderby": $orderby, "filter": $filter, "apiVersion": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Execute an Analytics query
#
# GET /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Insights/components/{applicationName}/query
# operationId: Query_Get
export def "subscriptions-resourcegroups-providers-microsoft-insights-components-query get" [
  subscription_id: string
  resource_group_name: string
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
  --query: string # The Analytics query. Learn more about the [Analytics query syntax](https://azure.microsoft.com/documentation/articles/app-insights-analytics-reference/)
  --timespan: string # Optional. The timespan over which to query data. This is an ISO8601 time period value. This timespan is applied in addition to any that are specified in the query expression.
  --api-version: string # Client API version.
]: nothing -> record<tables: table<columns: list, name: string, rows: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "timespan" $timespan "scalar") (serialize-qp "apiVersion" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Insights/components/{application_name}/query") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "timespan": $timespan, "apiVersion": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Execute an Analytics query
#
# POST /subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Insights/components/{applicationName}/query
# operationId: Query_Execute
export def "subscriptions-resourcegroups-providers-microsoft-insights-components-query list-execute" [
  subscription_id: string
  resource_group_name: string
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
  --api-version: string # Client API version.
  --applications: list<string> # Application IDs to include in cross-application queries.
  query: string # The Analytics query. Learn more about the [Analytics query syntax](https://azure.microsoft.com/documentation/articles/app-insights-analytics-reference/)
  --timespan: string # Optional. The timespan over which to query data. This is an ISO8601 time period value. This timespan is applied in addition to any that are specified in the query expression.
]: any -> record<tables: table<columns: list, name: string, rows: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($application_name | is-empty) { error make --unspanned { msg: "path parameter 'applicationName' must be non-empty" } }
  let qp = [(serialize-qp "apiVersion" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), application_name: (encode-path-segment $application_name)} | format pattern "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.Insights/components/{application_name}/query") $qp $auth.query)
  let req_body = {"applications": $applications, "query": $query, "timespan": $timespan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"apiVersion": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
