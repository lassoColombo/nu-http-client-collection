# Auto-generated client for Google Play Developer Reporting API vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/playdeveloperreporting/v1beta1/openapi.json
# Auth: --token flag or $env.GOOGLE_PLAY_DEVELOPER_REPORTING_API_TOKEN

const BASE_URL = "https://playdeveloperreporting.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://playdeveloperreporting.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def user-cohort-completer [] { ["APP_TESTERS" "OS_BETA" "OS_PUBLIC" "USER_COHORT_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1 get" } } | get name | first)
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

# Describes the properties of the metric set.
#
# GET /v1beta1/{name}
# operationId: playdeveloperreporting.vitals.stuckbackgroundwakelockrate.get
export def "v1beta1 get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<freshnessInfo: record<freshnesses: list<record>>, name: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Queries the metrics in the metric set.
#
# POST /v1beta1/{name}:query
# operationId: playdeveloperreporting.vitals.stuckbackgroundwakelockrate.query
# --timelineSpec shape: {aggregationPeriod?: "AGGREGATION_PERIOD_UNSPECIFIED"|"HOURLY"|"DAILY", endTime?: record, startTime?: record}
export def "v1beta1 list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dimensions: list<string> # Dimensions to slice the data by. **Supported dimensions:** * `apiLevel` (string): the API level of Android that was running on the user's device. * `versionCode` (int64): version of the app that was running on the user's device. * `deviceModel` (string): unique identifier of the user's device model. * `deviceType` (string): the type (also known as form factor) of the user's device. * `countryCode` (string): the country or region of the user's device based on their IP address, represented as a 2-letter ISO-3166 code (e.g. US for the United States). * `deviceRamBucket` (int64): RAM of the device, in MB, in buckets (3GB, 4GB, etc.). * `deviceSocMake` (string): Make of the device's primary system-on-chip, e.g., Samsung. [Reference](https://developer.android.com/reference/android/os/Build#SOC_MANUFACTURER) * `deviceSocModel` (string): Model of the device's primary system-on-chip, e.g., "Exynos 2100". [Reference](https://developer.android.com/reference/android/os/Build#SOC_MODEL) * `deviceCpuMake` (string): Make of the device's CPU, e.g., Qualcomm. * `deviceCpuModel` (string): Model of the device's CPU, e.g., "Kryo 240". * `deviceGpuMake` (string): Make of the device's GPU, e.g., ARM. * `deviceGpuModel` (string): Model of the device's GPU, e.g., Mali. * `deviceGpuVersion` (string): Version of the device's GPU, e.g., T750. * `deviceVulkanVersion` (string): Vulkan version of the device, e.g., "4198400". * `deviceGlEsVersion` (string): OpenGL ES version of the device, e.g., "196610". * `deviceScreenSize` (string): Screen size of the device, e.g., NORMAL, LARGE. * `deviceScreenDpi` (string): Screen density of the device, e.g., mdpi, hdpi.
  --filter: string # Filters to apply to data. The filtering expression follows [AIP-160](https://google.aip.dev/160) standard and supports filtering by equality of all breakdown dimensions.
  --metrics: list<string> # Metrics to aggregate. **Supported metrics:** * `stuckBgWakelockRate` (`google.type.Decimal`): Percentage of distinct users in the aggregation period that had a wakelock held in the background for longer than 1 hour. * `stuckBgWakelockRate7dUserWeighted` (`google.type.Decimal`): Rolling average value of `stuckBgWakelockRate` in the last 7 days. The daily values are weighted by the count of distinct users for the day. * `stuckBgWakelockRate28dUserWeighted` (`google.type.Decimal`): Rolling average value of `stuckBgWakelockRate` in the last 28 days. The daily values are weighted by the count of distinct users for the day. * `distinctUsers` (`google.type.Decimal`): Count of distinct users in the aggregation period that were used as normalization value for the `stuckBgWakelockRate` metric. A user is counted in this metric if they app was doing any work on the device, i.e., not just active foreground usage but also background work. Care must be taken not to aggregate this count further, as it may result in users being counted multiple times. The value is rounded to the nearest multiple of 10, 100, 1,000 or 1,000,000, depending on the magnitude of the value.
  --page-size: int # Maximum size of the returned data. If unspecified, at most 1000 rows will be returned. The maximum value is 100000; values above 100000 will be coerced to 100000. (format: int32)
  --page-token: string # A page token, received from a previous call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to the request must match the call that provided the page token.
  --timeline-spec: record # Specification of the time-related aggregation parameters of a timeline. Timelines have an aggregation period (`DAILY`, `HOURLY`, etc) which defines how events are aggregated in metrics. The points in a timeline are defined by the starting DateTime of the aggregation period. The duration is implicit in the AggregationPeriod. Hourly aggregation periods, when supported by a metric set, are always specified in UTC to avoid ambiguities around daylight saving time transitions, where an hour is skipped when adopting DST, and repeated when abandoning DST. For example, the timestamp '2021-11-07 01:00:00 America/Los_Angeles' is ambiguous since it can correspond to '2021-11-07 08:00:00 UTC' or '2021-11-07 09:00:00 UTC'. Daily aggregation periods require specifying a timezone which will determine the precise instants of the start and the end of the day. Not all metric sets support all timezones, so make sure to check which timezones are supported by the metric set you want to query. — shape: {aggregationPeriod?: "AGGREGATION_PERIOD_UNSPECIFIED"|"HOURLY"|"DAILY", endTime?: record, startTime?: record}
  --user-cohort: string@user-cohort-completer # User view to select. The output data will correspond to the selected view. **Supported values:** * `OS_PUBLIC` To select data from all publicly released Android versions. This is the default. Supports all the above dimensions. * `APP_TESTERS` To select data from users who have opted in to be testers. Supports all the above dimensions. * `OS_BETA` To select data from beta android versions only, excluding data from released android versions. Only the following dimensions are supported: * `versionCode` (int64): version of the app that was running on the user's device. * `osBuild` (string): OS build of the user's device, e.g., "T1B2.220916.004".
]: any -> record<nextPageToken: string, rows: table<aggregationPeriod: string, dimensions: list, metrics: list, startTime: record>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}:query") $qp)
  let req_body = {"dimensions": $dimensions, "filter": $filter, "metrics": $metrics, "pageSize": $page_size, "pageToken": $page_token, "timelineSpec": $timeline_spec, "userCohort": $user_cohort} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists anomalies in any of the datasets.
#
# GET /v1beta1/{parent}/anomalies
# operationId: playdeveloperreporting.anomalies.list
export def "v1beta1-anomalies list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filtering criteria for anomalies. For basic filter guidance, please check: https://google.aip.dev/160. **Supported functions:** * `activeBetween(startTime, endTime)`: If specified, only list anomalies that were active in between `startTime` (inclusive) and `endTime` (exclusive). Both parameters are expected to conform to an RFC-3339 formatted string (e.g. `2012-04-21T11:30:00-04:00`). UTC offsets are supported. Both `startTime` and `endTime` accept the special value `UNBOUNDED`, to signify intervals with no lower or upper bound, respectively. Examples: * `activeBetween("2021-04-21T11:30:00Z", "2021-07-21T00:00:00Z")` * `activeBetween(UNBOUNDED, "2021-11-21T00:00:00-04:00")` * `activeBetween("2021-07-21T00:00:00-04:00", UNBOUNDED)`
  --page-size: int # Maximum size of the returned data. If unspecified, at most 10 anomalies will be returned. The maximum value is 100; values above 100 will be coerced to 100.
  --page-token: string # A page token, received from a previous `ListErrorReports` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListErrorReports` must match the call that provided the page token.
]: nothing -> record<anomalies: table<dimensions: list, metric: record, metricSet: string, name: string, timelineSpec: record>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/anomalies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Searches all error issues in which reports have been grouped.
#
# GET /v1beta1/{parent}/errorIssues:search
# operationId: playdeveloperreporting.vitals.errors.issues.search
export def "v1beta1-error-issues-search list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A selection predicate to retrieve only a subset of the issues. Counts in the returned error issues will only reflect occurrences that matched the filter. For filtering basics, please check [AIP-160](https://google.aip.dev/160). ** Supported field names:** * `apiLevel`: Matches error issues that occurred in the requested Android versions (specified as the numeric API level) only. Example: `apiLevel = 28 OR apiLevel = 29`. * `versionCode`: Matches error issues that occurred in the requested app version codes only. Example: `versionCode = 123 OR versionCode = 456`. * `deviceModel`: Matches error issues that occurred in the requested devices. Example: `deviceModel = "walleye" OR deviceModel = "marlin"`. * `deviceType`: Matches error issues that occurred in the requested device types. Example: `deviceType = "PHONE"`. * `errorIssueType`: Matches error issues of the requested types only. Valid candidates: `CRASH`, `ANR`. Example: `errorIssueType = CRASH OR errorIssueType = ANR`. * `appProcessState`: Matches error issues on the process state of an app, indicating whether an app runs in the foreground (user-visible) or background. Valid candidates: `FOREGROUND`, `BACKGROUND`. Example: `appProcessState = FOREGROUND`. * `isUserPerceived`: Matches error issues that are user-perceived. It is not accompanied by any operators. Example: `isUserPerceived`. ** Supported operators:** * Comparison operators: The only supported comparison operator is equality. The filtered field must appear on the left hand side of the comparison. * Logical Operators: Logical operators `AND` and `OR` can be used to build complex filters following a conjunctive normal form (CNF), i.e., conjunctions of disjunctions. The `OR` operator takes precedence over `AND` so the use of parenthesis is not necessary when building CNF. The `OR` operator is only supported to build disjunctions that apply to the same field, e.g., `versionCode = 123 OR errorIssueType = ANR` is not a valid filter. ** Examples ** Some valid filtering expressions: * `versionCode = 123 AND errorIssueType = ANR` * `versionCode = 123 AND errorIssueType = OR errorIssueType = CRASH` * `versionCode = 123 AND (errorIssueType = OR errorIssueType = CRASH)`
  --interval-end-time-day: int # Optional. Day of month. Must be from 1 to 31 and valid for the year and month, or 0 if specifying a datetime without a day.
  --interval-end-time-hours: int # Optional. Hours of day in 24 hour format. Should be from 0 to 23, defaults to 0 (midnight). An API may choose to allow the value "24:00:00" for scenarios like business closing time.
  --interval-end-time-minutes: int # Optional. Minutes of hour of day. Must be from 0 to 59, defaults to 0.
  --interval-end-time-month: int # Optional. Month of year. Must be from 1 to 12, or 0 if specifying a datetime without a month.
  --interval-end-time-nanos: int # Optional. Fractions of seconds in nanoseconds. Must be from 0 to 999,999,999, defaults to 0.
  --interval-end-time-seconds: int # Optional. Seconds of minutes of the time. Must normally be from 0 to 59, defaults to 0. An API may allow the value 60 if it allows leap-seconds.
  --interval-end-time-time-zone-id: string # IANA Time Zone Database time zone, e.g. "America/New_York".
  --interval-end-time-time-zone-version: string # Optional. IANA Time Zone Database version number, e.g. "2019a".
  --interval-end-time-utc-offset: string # UTC offset. Must be whole seconds, between -18 hours and +18 hours. For example, a UTC offset of -4:00 would be represented as { seconds: -14400 }.
  --interval-end-time-year: int # Optional. Year of date. Must be from 1 to 9999, or 0 if specifying a datetime without a year.
  --interval-start-time-day: int # Optional. Day of month. Must be from 1 to 31 and valid for the year and month, or 0 if specifying a datetime without a day.
  --interval-start-time-hours: int # Optional. Hours of day in 24 hour format. Should be from 0 to 23, defaults to 0 (midnight). An API may choose to allow the value "24:00:00" for scenarios like business closing time.
  --interval-start-time-minutes: int # Optional. Minutes of hour of day. Must be from 0 to 59, defaults to 0.
  --interval-start-time-month: int # Optional. Month of year. Must be from 1 to 12, or 0 if specifying a datetime without a month.
  --interval-start-time-nanos: int # Optional. Fractions of seconds in nanoseconds. Must be from 0 to 999,999,999, defaults to 0.
  --interval-start-time-seconds: int # Optional. Seconds of minutes of the time. Must normally be from 0 to 59, defaults to 0. An API may allow the value 60 if it allows leap-seconds.
  --interval-start-time-time-zone-id: string # IANA Time Zone Database time zone, e.g. "America/New_York".
  --interval-start-time-time-zone-version: string # Optional. IANA Time Zone Database version number, e.g. "2019a".
  --interval-start-time-utc-offset: string # UTC offset. Must be whole seconds, between -18 hours and +18 hours. For example, a UTC offset of -4:00 would be represented as { seconds: -14400 }.
  --interval-start-time-year: int # Optional. Year of date. Must be from 1 to 9999, or 0 if specifying a datetime without a year.
  --page-size: int # The maximum number of error issues to return. The service may return fewer than this value. If unspecified, at most 50 error issues will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to the request must match the call that provided the page token.
]: nothing -> record<errorIssues: table<cause: string, location: string, name: string, type: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "interval.endTime.day" $interval_end_time_day "scalar") (serialize-qp "interval.endTime.hours" $interval_end_time_hours "scalar") (serialize-qp "interval.endTime.minutes" $interval_end_time_minutes "scalar") (serialize-qp "interval.endTime.month" $interval_end_time_month "scalar") (serialize-qp "interval.endTime.nanos" $interval_end_time_nanos "scalar") (serialize-qp "interval.endTime.seconds" $interval_end_time_seconds "scalar") (serialize-qp "interval.endTime.timeZone.id" $interval_end_time_time_zone_id "scalar") (serialize-qp "interval.endTime.timeZone.version" $interval_end_time_time_zone_version "scalar") (serialize-qp "interval.endTime.utcOffset" $interval_end_time_utc_offset "scalar") (serialize-qp "interval.endTime.year" $interval_end_time_year "scalar") (serialize-qp "interval.startTime.day" $interval_start_time_day "scalar") (serialize-qp "interval.startTime.hours" $interval_start_time_hours "scalar") (serialize-qp "interval.startTime.minutes" $interval_start_time_minutes "scalar") (serialize-qp "interval.startTime.month" $interval_start_time_month "scalar") (serialize-qp "interval.startTime.nanos" $interval_start_time_nanos "scalar") (serialize-qp "interval.startTime.seconds" $interval_start_time_seconds "scalar") (serialize-qp "interval.startTime.timeZone.id" $interval_start_time_time_zone_id "scalar") (serialize-qp "interval.startTime.timeZone.version" $interval_start_time_time_zone_version "scalar") (serialize-qp "interval.startTime.utcOffset" $interval_start_time_utc_offset "scalar") (serialize-qp "interval.startTime.year" $interval_start_time_year "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/errorIssues:search") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "interval.endTime.day": $interval_end_time_day, "interval.endTime.hours": $interval_end_time_hours, "interval.endTime.minutes": $interval_end_time_minutes, "interval.endTime.month": $interval_end_time_month, "interval.endTime.nanos": $interval_end_time_nanos, "interval.endTime.seconds": $interval_end_time_seconds, "interval.endTime.timeZone.id": $interval_end_time_time_zone_id, "interval.endTime.timeZone.version": $interval_end_time_time_zone_version, "interval.endTime.utcOffset": $interval_end_time_utc_offset, "interval.endTime.year": $interval_end_time_year, "interval.startTime.day": $interval_start_time_day, "interval.startTime.hours": $interval_start_time_hours, "interval.startTime.minutes": $interval_start_time_minutes, "interval.startTime.month": $interval_start_time_month, "interval.startTime.nanos": $interval_start_time_nanos, "interval.startTime.seconds": $interval_start_time_seconds, "interval.startTime.timeZone.id": $interval_start_time_time_zone_id, "interval.startTime.timeZone.version": $interval_start_time_time_zone_version, "interval.startTime.utcOffset": $interval_start_time_utc_offset, "interval.startTime.year": $interval_start_time_year, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Searches all error reports received for an app.
#
# GET /v1beta1/{parent}/errorReports:search
# operationId: playdeveloperreporting.vitals.errors.reports.search
export def "v1beta1-error-reports-search list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A selection predicate to retrieve only a subset of the reports. For filtering basics, please check [AIP-160](https://google.aip.dev/160). ** Supported field names:** * `apiLevel`: Matches error reports that occurred in the requested Android versions (specified as the numeric API level) only. Example: `apiLevel = 28 OR apiLevel = 29`. * `versionCode`: Matches error reports that occurred in the requested app version codes only. Example: `versionCode = 123 OR versionCode = 456`. * `deviceModel`: Matches error reports that occurred in the requested devices. Example: `deviceModel = "walleye" OR deviceModel = "marlin"`. * `deviceType`: Matches error reports that occurred in the requested device types. Example: `deviceType = "PHONE"`. * `errorIssueType`: Matches error reports of the requested types only. Valid candidates: `JAVA_CRASH`, `NATIVE_CRASH`, `ANR`. Example: `errorIssueType = JAVA_CRASH OR errorIssueType = NATIVE_CRASH`. * `errorIssueId`: Matches error reports belonging to the requested error issue ids only. Example: `errorIssueId = 1234 OR errorIssueId = 4567`. * `appProcessState`: Matches error reports on the process state of an app, indicating whether an app runs in the foreground (user-visible) or background. Valid candidates: `FOREGROUND`, `BACKGROUND`. Example: `appProcessState = FOREGROUND`. * `isUserPerceived`: Matches error reports that are user-perceived. It is not accompanied by any operators. Example: `isUserPerceived`. ** Supported operators:** * Comparison operators: The only supported comparison operator is equality. The filtered field must appear on the left hand side of the comparison. * Logical Operators: Logical operators `AND` and `OR` can be used to build complex filters following a conjunctive normal form (CNF), i.e., conjunctions of disjunctions. The `OR` operator takes precedence over `AND` so the use of parenthesis is not necessary when building CNF. The `OR` operator is only supported to build disjunctions that apply to the same field, e.g., `versionCode = 123 OR versionCode = ANR`. The filter expression `versionCode = 123 OR errorIssueType = ANR` is not valid. ** Examples ** Some valid filtering expressions: * `versionCode = 123 AND errorIssueType = ANR` * `versionCode = 123 AND errorIssueType = OR errorIssueType = CRASH` * `versionCode = 123 AND (errorIssueType = OR errorIssueType = CRASH)`
  --interval-end-time-day: int # Optional. Day of month. Must be from 1 to 31 and valid for the year and month, or 0 if specifying a datetime without a day.
  --interval-end-time-hours: int # Optional. Hours of day in 24 hour format. Should be from 0 to 23, defaults to 0 (midnight). An API may choose to allow the value "24:00:00" for scenarios like business closing time.
  --interval-end-time-minutes: int # Optional. Minutes of hour of day. Must be from 0 to 59, defaults to 0.
  --interval-end-time-month: int # Optional. Month of year. Must be from 1 to 12, or 0 if specifying a datetime without a month.
  --interval-end-time-nanos: int # Optional. Fractions of seconds in nanoseconds. Must be from 0 to 999,999,999, defaults to 0.
  --interval-end-time-seconds: int # Optional. Seconds of minutes of the time. Must normally be from 0 to 59, defaults to 0. An API may allow the value 60 if it allows leap-seconds.
  --interval-end-time-time-zone-id: string # IANA Time Zone Database time zone, e.g. "America/New_York".
  --interval-end-time-time-zone-version: string # Optional. IANA Time Zone Database version number, e.g. "2019a".
  --interval-end-time-utc-offset: string # UTC offset. Must be whole seconds, between -18 hours and +18 hours. For example, a UTC offset of -4:00 would be represented as { seconds: -14400 }.
  --interval-end-time-year: int # Optional. Year of date. Must be from 1 to 9999, or 0 if specifying a datetime without a year.
  --interval-start-time-day: int # Optional. Day of month. Must be from 1 to 31 and valid for the year and month, or 0 if specifying a datetime without a day.
  --interval-start-time-hours: int # Optional. Hours of day in 24 hour format. Should be from 0 to 23, defaults to 0 (midnight). An API may choose to allow the value "24:00:00" for scenarios like business closing time.
  --interval-start-time-minutes: int # Optional. Minutes of hour of day. Must be from 0 to 59, defaults to 0.
  --interval-start-time-month: int # Optional. Month of year. Must be from 1 to 12, or 0 if specifying a datetime without a month.
  --interval-start-time-nanos: int # Optional. Fractions of seconds in nanoseconds. Must be from 0 to 999,999,999, defaults to 0.
  --interval-start-time-seconds: int # Optional. Seconds of minutes of the time. Must normally be from 0 to 59, defaults to 0. An API may allow the value 60 if it allows leap-seconds.
  --interval-start-time-time-zone-id: string # IANA Time Zone Database time zone, e.g. "America/New_York".
  --interval-start-time-time-zone-version: string # Optional. IANA Time Zone Database version number, e.g. "2019a".
  --interval-start-time-utc-offset: string # UTC offset. Must be whole seconds, between -18 hours and +18 hours. For example, a UTC offset of -4:00 would be represented as { seconds: -14400 }.
  --interval-start-time-year: int # Optional. Year of date. Must be from 1 to 9999, or 0 if specifying a datetime without a year.
  --page-size: int # The maximum number of reports to return. The service may return fewer than this value. If unspecified, at most 50 reports will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --page-token: string # A page token, received from a previous `SearchErrorReports` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `SearchErrorReports` must match the call that provided the page token.
]: nothing -> record<errorReports: table<issue: string, name: string, reportText: string, type: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o GOOGLE_PLAY_DEVELOPER_REPORTING_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "interval.endTime.day" $interval_end_time_day "scalar") (serialize-qp "interval.endTime.hours" $interval_end_time_hours "scalar") (serialize-qp "interval.endTime.minutes" $interval_end_time_minutes "scalar") (serialize-qp "interval.endTime.month" $interval_end_time_month "scalar") (serialize-qp "interval.endTime.nanos" $interval_end_time_nanos "scalar") (serialize-qp "interval.endTime.seconds" $interval_end_time_seconds "scalar") (serialize-qp "interval.endTime.timeZone.id" $interval_end_time_time_zone_id "scalar") (serialize-qp "interval.endTime.timeZone.version" $interval_end_time_time_zone_version "scalar") (serialize-qp "interval.endTime.utcOffset" $interval_end_time_utc_offset "scalar") (serialize-qp "interval.endTime.year" $interval_end_time_year "scalar") (serialize-qp "interval.startTime.day" $interval_start_time_day "scalar") (serialize-qp "interval.startTime.hours" $interval_start_time_hours "scalar") (serialize-qp "interval.startTime.minutes" $interval_start_time_minutes "scalar") (serialize-qp "interval.startTime.month" $interval_start_time_month "scalar") (serialize-qp "interval.startTime.nanos" $interval_start_time_nanos "scalar") (serialize-qp "interval.startTime.seconds" $interval_start_time_seconds "scalar") (serialize-qp "interval.startTime.timeZone.id" $interval_start_time_time_zone_id "scalar") (serialize-qp "interval.startTime.timeZone.version" $interval_start_time_time_zone_version "scalar") (serialize-qp "interval.startTime.utcOffset" $interval_start_time_utc_offset "scalar") (serialize-qp "interval.startTime.year" $interval_start_time_year "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/errorReports:search") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "interval.endTime.day": $interval_end_time_day, "interval.endTime.hours": $interval_end_time_hours, "interval.endTime.minutes": $interval_end_time_minutes, "interval.endTime.month": $interval_end_time_month, "interval.endTime.nanos": $interval_end_time_nanos, "interval.endTime.seconds": $interval_end_time_seconds, "interval.endTime.timeZone.id": $interval_end_time_time_zone_id, "interval.endTime.timeZone.version": $interval_end_time_time_zone_version, "interval.endTime.utcOffset": $interval_end_time_utc_offset, "interval.endTime.year": $interval_end_time_year, "interval.startTime.day": $interval_start_time_day, "interval.startTime.hours": $interval_start_time_hours, "interval.startTime.minutes": $interval_start_time_minutes, "interval.startTime.month": $interval_start_time_month, "interval.startTime.nanos": $interval_start_time_nanos, "interval.startTime.seconds": $interval_start_time_seconds, "interval.startTime.timeZone.id": $interval_start_time_time_zone_id, "interval.startTime.timeZone.version": $interval_start_time_time_zone_version, "interval.startTime.utcOffset": $interval_start_time_utc_offset, "interval.startTime.year": $interval_start_time_year, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}
