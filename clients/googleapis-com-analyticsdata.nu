# Auto-generated client for Google Analytics Data API vv1beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/analyticsdata/v1beta/openapi.json
# Auth: --token flag or $env.GOOGLE_ANALYTICS_DATA_API_TOKEN

const BASE_URL = "https://analyticsdata.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_ANALYTICS_DATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["https://analyticsdata.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def compatibilityFilter-completer [] { ["COMPATIBILITY_UNSPECIFIED" "COMPATIBLE" "INCOMPATIBLE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta analyticsdatapropertiesgetMetadata" } } | get name | first)
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

# Returns metadata for dimensions and metrics available in reporting methods. Used to explore the dimensions and metrics. In this method, a Google Analytics GA4 Property Identifier is specified in the request, and the metadata response includes Custom dimensions and metrics as well as Universal metadata. For example if a custom metric with parameter name `levels_unlocked` is registered to a property, the Metadata response will contain `customEvent:levels_unlocked`. Universal metadata are dimensions and metrics applicable to any property such as `country` and `totalUsers`.
#
# GET /v1beta/{name}
# operationId: analyticsdata.properties.getMetadata
export def "v1beta analyticsdatapropertiesgetMetadata" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<dimensions: table<apiName: string, category: string, customDefinition: bool, deprecatedApiNames: list, description: string, uiName: string>, metrics: table<apiName: string, blockedReasons: list, category: string, customDefinition: bool, deprecatedApiNames: list, description: string, expression: string, type: string, uiName: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns multiple pivot reports in a batch. All reports must be for the same GA4 Property.
#
# POST /v1beta/{property}:batchRunPivotReports
# operationId: analyticsdata.properties.batchRunPivotReports
# --requests item shape: {cohortSpec?: record, currencyCode?: string, dateRanges?: list, dimensionFilter?: record, dimensions?: list, keepEmptyRows?: bool, metricFilter?: record, metrics?: list, pivots?: list, property?: string, returnPropertyQuota?: bool}
export def "v1beta analyticsdatapropertiesbatchRunPivotReports" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --requests: list # Individual requests. Each request has a separate pivot report response. Each batch request is allowed up to 5 requests. — item shape: {cohortSpec?: record, currencyCode?: string, dateRanges?: list, dimensionFilter?: record, dimensions?: list, keepEmptyRows?: bool, metricFilter?: record, metrics?: list, pivots?: list, property?: string, returnPropertyQuota?: bool}
]: any -> record<kind: string, pivotReports: table<aggregates: list, dimensionHeaders: list, kind: string, metadata: record, metricHeaders: list, pivotHeaders: list, propertyQuota: record, rows: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($property):batchRunPivotReports" $qp)
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns multiple reports in a batch. All reports must be for the same GA4 Property.
#
# POST /v1beta/{property}:batchRunReports
# operationId: analyticsdata.properties.batchRunReports
# --requests item shape: {cohortSpec?: record, currencyCode?: string, dateRanges?: list, dimensionFilter?: record, dimensions?: list, keepEmptyRows?: bool, limit?: string, metricAggregations?: list, metricFilter?: record, metrics?: list, offset?: string, orderBys?: list, property?: string, returnPropertyQuota?: bool}
export def "v1beta analyticsdatapropertiesbatchRunReports" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --requests: list # Individual requests. Each request has a separate report response. Each batch request is allowed up to 5 requests. — item shape: {cohortSpec?: record, currencyCode?: string, dateRanges?: list, dimensionFilter?: record, dimensions?: list, keepEmptyRows?: bool, limit?: string, metricAggregations?: list, metricFilter?: record, metrics?: list, offset?: string, orderBys?: list, property?: string, returnPropertyQuota?: bool}
]: any -> record<kind: string, reports: table<dimensionHeaders: list, kind: string, maximums: list, metadata: record, metricHeaders: list, minimums: list, propertyQuota: record, rowCount: int, rows: list, totals: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($property):batchRunReports" $qp)
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This compatibility method lists dimensions and metrics that can be added to a report request and maintain compatibility. This method fails if the request's dimensions and metrics are incompatible. In Google Analytics, reports fail if they request incompatible dimensions and/or metrics; in that case, you will need to remove dimensions and/or metrics from the incompatible report until the report is compatible. The Realtime and Core reports have different compatibility rules. This method checks compatibility for Core reports.
#
# POST /v1beta/{property}:checkCompatibility
# operationId: analyticsdata.properties.checkCompatibility
# --dimensionFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --dimensions item shape: {dimensionExpression?: record, name?: string}
# --metricFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --metrics item shape: {expression?: string, invisible?: bool, name?: string}
export def "v1beta analyticsdatapropertiescheckCompatibility" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --compatibilityFilter: string@compatibilityFilter-completer # Filters the dimensions and metrics in the response to just this compatibility. Commonly used as `”compatibilityFilter”: “COMPATIBLE”` to only return compatible dimensions & metrics.
  --dimensionFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --dimensions: list # The dimensions in this report. `dimensions` should be the same value as in your `runReport` request. — item shape: {dimensionExpression?: record, name?: string}
  --metricFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --metrics: list # The metrics in this report. `metrics` should be the same value as in your `runReport` request. — item shape: {expression?: string, invisible?: bool, name?: string}
]: any -> record<dimensionCompatibilities: table<compatibility: string, dimensionMetadata: record>, metricCompatibilities: table<compatibility: string, metricMetadata: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($property):checkCompatibility" $qp)
  let body = {compatibilityFilter: $compatibilityFilter, dimensionFilter: $dimensionFilter, dimensions: $dimensions, metricFilter: $metricFilter, metrics: $metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a customized pivot report of your Google Analytics event data. Pivot reports are more advanced and expressive formats than regular reports. In a pivot report, dimensions are only visible if they are included in a pivot. Multiple pivots can be specified to further dissect your data.
#
# POST /v1beta/{property}:runPivotReport
# operationId: analyticsdata.properties.runPivotReport
# --cohortSpec shape: {cohortReportSettings?: record, cohorts?: list, cohortsRange?: record}
# --dateRanges item shape: {endDate?: string, name?: string, startDate?: string}
# --dimensionFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --dimensions item shape: {dimensionExpression?: record, name?: string}
# --metricFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --metrics item shape: {expression?: string, invisible?: bool, name?: string}
# --pivots item shape: {fieldNames?: list, limit?: string, metricAggregations?: list, offset?: string, orderBys?: list}
export def "v1beta analyticsdatapropertiesrunPivotReport" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cohortSpec: record # The specification of cohorts for a cohort report. Cohort reports create a time series of user retention for the cohort. For example, you could select the cohort of users that were acquired in the first week of September and follow that cohort for the next six weeks. Selecting the users acquired in the first week of September cohort is specified in the `cohort` object. Following that cohort for the next six weeks is specified in the `cohortsRange` object. For examples, see [Cohort Report Examples](https://developers.google.com/analytics/devguides/reporting/data/v1/advanced#cohort_report_examples). The report response could show a weekly time series where say your app has retained 60% of this cohort after three weeks and 25% of this cohort after six weeks. These two percentages can be calculated by the metric `cohortActiveUsers/cohortTotalUsers` and will be separate rows in the report. — shape: {cohortReportSettings?: record, cohorts?: list, cohortsRange?: record}
  --currencyCode: string # A currency code in ISO4217 format, such as "AED", "USD", "JPY". If the field is empty, the report uses the property's default currency.
  --dateRanges: list # The date range to retrieve event data for the report. If multiple date ranges are specified, event data from each date range is used in the report. A special dimension with field name "dateRange" can be included in a Pivot's field names; if included, the report compares between date ranges. In a cohort request, this `dateRanges` must be unspecified. — item shape: {endDate?: string, name?: string, startDate?: string}
  --dimensionFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --dimensions: list # The dimensions requested. All defined dimensions must be used by one of the following: dimension_expression, dimension_filter, pivots, order_bys. — item shape: {dimensionExpression?: record, name?: string}
  --keepEmptyRows: oneof<nothing, bool> # If false or unspecified, each row with all metrics equal to 0 will not be returned. If true, these rows will be returned if they are not separately removed by a filter. Regardless of this `keep_empty_rows` setting, only data recorded by the Google Analytics (GA4) property can be displayed in a report. For example if a property never logs a `purchase` event, then a query for the `eventName` dimension and `eventCount` metric will not have a row eventName: "purchase" and eventCount: 0.
  --metricFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --metrics: list # The metrics requested, at least one metric needs to be specified. All defined metrics must be used by one of the following: metric_expression, metric_filter, order_bys. — item shape: {expression?: string, invisible?: bool, name?: string}
  --pivots: list # Describes the visual format of the report's dimensions in columns or rows. The union of the fieldNames (dimension names) in all pivots must be a subset of dimension names defined in Dimensions. No two pivots can share a dimension. A dimension is only visible if it appears in a pivot. — item shape: {fieldNames?: list, limit?: string, metricAggregations?: list, offset?: string, orderBys?: list}
  --body-property: string # A Google Analytics GA4 property identifier whose events are tracked. Specified in the URL path and not the body. To learn more, see [where to find your Property ID](https://developers.google.com/analytics/devguides/reporting/data/v1/property-id). Within a batch request, this property should either be unspecified or consistent with the batch-level property. Example: properties/1234
  --returnPropertyQuota: oneof<nothing, bool> # Toggles whether to return the current state of this Analytics Property's quota. Quota is returned in [PropertyQuota](#PropertyQuota).
]: any -> record<aggregates: table<dimensionValues: list, metricValues: list>, dimensionHeaders: table<name: string>, kind: string, metadata: record<currencyCode: string, dataLossFromOtherRow: bool, emptyReason: string, schemaRestrictionResponse: record<activeMetricRestrictions: list>, subjectToThresholding: bool, timeZone: string>, metricHeaders: table<name: string, type: string>, pivotHeaders: table<pivotDimensionHeaders: list, rowCount: int>, propertyQuota: record<concurrentRequests: record<consumed: int, remaining: int>, potentiallyThresholdedRequestsPerHour: record<consumed: int, remaining: int>, serverErrorsPerProjectPerHour: record<consumed: int, remaining: int>, tokensPerDay: record<consumed: int, remaining: int>, tokensPerHour: record<consumed: int, remaining: int>, tokensPerProjectPerHour: record<consumed: int, remaining: int>>, rows: table<dimensionValues: list, metricValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($property):runPivotReport" $qp)
  let body = {cohortSpec: $cohortSpec, currencyCode: $currencyCode, dateRanges: $dateRanges, dimensionFilter: $dimensionFilter, dimensions: $dimensions, keepEmptyRows: $keepEmptyRows, metricFilter: $metricFilter, metrics: $metrics, pivots: $pivots, property: $body_property, returnPropertyQuota: $returnPropertyQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a customized report of realtime event data for your property. Events appear in realtime reports seconds after they have been sent to the Google Analytics. Realtime reports show events and usage data for the periods of time ranging from the present moment to 30 minutes ago (up to 60 minutes for Google Analytics 360 properties). For a guide to constructing realtime requests & understanding responses, see [Creating a Realtime Report](https://developers.google.com/analytics/devguides/reporting/data/v1/realtime-basics).
#
# POST /v1beta/{property}:runRealtimeReport
# operationId: analyticsdata.properties.runRealtimeReport
# --dimensionFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --dimensions item shape: {dimensionExpression?: record, name?: string}
# --metricFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --metrics item shape: {expression?: string, invisible?: bool, name?: string}
# --minuteRanges item shape: {endMinutesAgo?: int, name?: string, startMinutesAgo?: int}
# --orderBys item shape: {desc?: bool, dimension?: record, metric?: record, pivot?: record}
export def "v1beta analyticsdatapropertiesrunRealtimeReport" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dimensionFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --dimensions: list # The dimensions requested and displayed. — item shape: {dimensionExpression?: record, name?: string}
  --limit: string # The number of rows to return. If unspecified, 10,000 rows are returned. The API returns a maximum of 250,000 rows per request, no matter how many you ask for. `limit` must be positive. The API can also return fewer rows than the requested `limit`, if there aren't as many dimension values as the `limit`. For instance, there are fewer than 300 possible values for the dimension `country`, so when reporting on only `country`, you can't get more than 300 rows, even if you set `limit` to a higher value. (format: int64)
  --metricAggregations: list # Aggregation of metrics. Aggregated metric values will be shown in rows where the dimension_values are set to "RESERVED_(MetricAggregation)".
  --metricFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --metrics: list # The metrics requested and displayed. — item shape: {expression?: string, invisible?: bool, name?: string}
  --minuteRanges: list # The minute ranges of event data to read. If unspecified, one minute range for the last 30 minutes will be used. If multiple minute ranges are requested, each response row will contain a zero based minute range index. If two minute ranges overlap, the event data for the overlapping minutes is included in the response rows for both minute ranges. — item shape: {endMinutesAgo?: int, name?: string, startMinutesAgo?: int}
  --orderBys: list # Specifies how rows are ordered in the response. — item shape: {desc?: bool, dimension?: record, metric?: record, pivot?: record}
  --returnPropertyQuota: oneof<nothing, bool> # Toggles whether to return the current state of this Analytics Property's Realtime quota. Quota is returned in [PropertyQuota](#PropertyQuota).
]: any -> record<dimensionHeaders: table<name: string>, kind: string, maximums: table<dimensionValues: list, metricValues: list>, metricHeaders: table<name: string, type: string>, minimums: table<dimensionValues: list, metricValues: list>, propertyQuota: record<concurrentRequests: record<consumed: int, remaining: int>, potentiallyThresholdedRequestsPerHour: record<consumed: int, remaining: int>, serverErrorsPerProjectPerHour: record<consumed: int, remaining: int>, tokensPerDay: record<consumed: int, remaining: int>, tokensPerHour: record<consumed: int, remaining: int>, tokensPerProjectPerHour: record<consumed: int, remaining: int>>, rowCount: int, rows: table<dimensionValues: list, metricValues: list>, totals: table<dimensionValues: list, metricValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($property):runRealtimeReport" $qp)
  let body = {dimensionFilter: $dimensionFilter, dimensions: $dimensions, limit: $limit, metricAggregations: $metricAggregations, metricFilter: $metricFilter, metrics: $metrics, minuteRanges: $minuteRanges, orderBys: $orderBys, returnPropertyQuota: $returnPropertyQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a customized report of your Google Analytics event data. Reports contain statistics derived from data collected by the Google Analytics tracking code. The data returned from the API is as a table with columns for the requested dimensions and metrics. Metrics are individual measurements of user activity on your property, such as active users or event count. Dimensions break down metrics across some common criteria, such as country or event name. For a guide to constructing requests & understanding responses, see [Creating a Report](https://developers.google.com/analytics/devguides/reporting/data/v1/basics).
#
# POST /v1beta/{property}:runReport
# operationId: analyticsdata.properties.runReport
# --cohortSpec shape: {cohortReportSettings?: record, cohorts?: list, cohortsRange?: record}
# --dateRanges item shape: {endDate?: string, name?: string, startDate?: string}
# --dimensionFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --dimensions item shape: {dimensionExpression?: record, name?: string}
# --metricFilter shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
# --metrics item shape: {expression?: string, invisible?: bool, name?: string}
# --orderBys item shape: {desc?: bool, dimension?: record, metric?: record, pivot?: record}
export def "v1beta analyticsdatapropertiesrunReport" [
  property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cohortSpec: record # The specification of cohorts for a cohort report. Cohort reports create a time series of user retention for the cohort. For example, you could select the cohort of users that were acquired in the first week of September and follow that cohort for the next six weeks. Selecting the users acquired in the first week of September cohort is specified in the `cohort` object. Following that cohort for the next six weeks is specified in the `cohortsRange` object. For examples, see [Cohort Report Examples](https://developers.google.com/analytics/devguides/reporting/data/v1/advanced#cohort_report_examples). The report response could show a weekly time series where say your app has retained 60% of this cohort after three weeks and 25% of this cohort after six weeks. These two percentages can be calculated by the metric `cohortActiveUsers/cohortTotalUsers` and will be separate rows in the report. — shape: {cohortReportSettings?: record, cohorts?: list, cohortsRange?: record}
  --currencyCode: string # A currency code in ISO4217 format, such as "AED", "USD", "JPY". If the field is empty, the report uses the property's default currency.
  --dateRanges: list # Date ranges of data to read. If multiple date ranges are requested, each response row will contain a zero based date range index. If two date ranges overlap, the event data for the overlapping days is included in the response rows for both date ranges. In a cohort request, this `dateRanges` must be unspecified. — item shape: {endDate?: string, name?: string, startDate?: string}
  --dimensionFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --dimensions: list # The dimensions requested and displayed. — item shape: {dimensionExpression?: record, name?: string}
  --keepEmptyRows: oneof<nothing, bool> # If false or unspecified, each row with all metrics equal to 0 will not be returned. If true, these rows will be returned if they are not separately removed by a filter. Regardless of this `keep_empty_rows` setting, only data recorded by the Google Analytics (GA4) property can be displayed in a report. For example if a property never logs a `purchase` event, then a query for the `eventName` dimension and `eventCount` metric will not have a row eventName: "purchase" and eventCount: 0.
  --limit: string # The number of rows to return. If unspecified, 10,000 rows are returned. The API returns a maximum of 250,000 rows per request, no matter how many you ask for. `limit` must be positive. The API can also return fewer rows than the requested `limit`, if there aren't as many dimension values as the `limit`. For instance, there are fewer than 300 possible values for the dimension `country`, so when reporting on only `country`, you can't get more than 300 rows, even if you set `limit` to a higher value. To learn more about this pagination parameter, see [Pagination](https://developers.google.com/analytics/devguides/reporting/data/v1/basics#pagination). (format: int64)
  --metricAggregations: list # Aggregation of metrics. Aggregated metric values will be shown in rows where the dimension_values are set to "RESERVED_(MetricAggregation)".
  --metricFilter: record # To express dimension or metric filters. The fields in the same FilterExpression need to be either all dimensions or all metrics. — shape: {andGroup?: record, filter?: record, notExpression?: record, orGroup?: record}
  --metrics: list # The metrics requested and displayed. — item shape: {expression?: string, invisible?: bool, name?: string}
  --offset: string # The row count of the start row. The first row is counted as row 0. When paging, the first request does not specify offset; or equivalently, sets offset to 0; the first request returns the first `limit` of rows. The second request sets offset to the `limit` of the first request; the second request returns the second `limit` of rows. To learn more about this pagination parameter, see [Pagination](https://developers.google.com/analytics/devguides/reporting/data/v1/basics#pagination). (format: int64)
  --orderBys: list # Specifies how rows are ordered in the response. — item shape: {desc?: bool, dimension?: record, metric?: record, pivot?: record}
  --body-property: string # A Google Analytics GA4 property identifier whose events are tracked. Specified in the URL path and not the body. To learn more, see [where to find your Property ID](https://developers.google.com/analytics/devguides/reporting/data/v1/property-id). Within a batch request, this property should either be unspecified or consistent with the batch-level property. Example: properties/1234
  --returnPropertyQuota: oneof<nothing, bool> # Toggles whether to return the current state of this Analytics Property's quota. Quota is returned in [PropertyQuota](#PropertyQuota).
]: any -> record<dimensionHeaders: table<name: string>, kind: string, maximums: table<dimensionValues: list, metricValues: list>, metadata: record<currencyCode: string, dataLossFromOtherRow: bool, emptyReason: string, schemaRestrictionResponse: record<activeMetricRestrictions: list>, subjectToThresholding: bool, timeZone: string>, metricHeaders: table<name: string, type: string>, minimums: table<dimensionValues: list, metricValues: list>, propertyQuota: record<concurrentRequests: record<consumed: int, remaining: int>, potentiallyThresholdedRequestsPerHour: record<consumed: int, remaining: int>, serverErrorsPerProjectPerHour: record<consumed: int, remaining: int>, tokensPerDay: record<consumed: int, remaining: int>, tokensPerHour: record<consumed: int, remaining: int>, tokensPerProjectPerHour: record<consumed: int, remaining: int>>, rowCount: int, rows: table<dimensionValues: list, metricValues: list>, totals: table<dimensionValues: list, metricValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($property):runReport" $qp)
  let body = {cohortSpec: $cohortSpec, currencyCode: $currencyCode, dateRanges: $dateRanges, dimensionFilter: $dimensionFilter, dimensions: $dimensions, keepEmptyRows: $keepEmptyRows, limit: $limit, metricAggregations: $metricAggregations, metricFilter: $metricFilter, metrics: $metrics, offset: $offset, orderBys: $orderBys, property: $body_property, returnPropertyQuota: $returnPropertyQuota} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
