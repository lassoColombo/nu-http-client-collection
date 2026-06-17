# Auto-generated client for DoubleClick Bid Manager API vv1.1
# Source: https://api.apis.guru/v2/specs/googleapis.com/doubleclickbidmanager/v1.1/openapi.json
# Auth: --token flag or $env.DOUBLECLICK_BID_MANAGER_API_TOKEN

const BASE_URL = "https://doubleclickbidmanager.googleapis.com/doubleclickbidmanager/v1.1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DOUBLECLICK_BID_MANAGER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://doubleclickbidmanager.googleapis.com/doubleclickbidmanager/v1.1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def data-range-completer [] { ["ALL_TIME" "CURRENT_DAY" "CUSTOM_DATES" "LAST_14_DAYS" "LAST_30_DAYS" "LAST_365_DAYS" "LAST_60_DAYS" "LAST_7_DAYS" "LAST_90_DAYS" "MONTH_TO_DATE" "PREVIOUS_DAY" "PREVIOUS_HALF_MONTH" "PREVIOUS_MONTH" "PREVIOUS_QUARTER" "PREVIOUS_WEEK" "PREVIOUS_YEAR" "QUARTER_TO_DATE" "TYPE_NOT_SUPPORTED" "WEEK_TO_DATE" "YEAR_TO_DATE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "queries doubleclickbidmanagerquerieslistqueries" } } | get name | first)
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

# Retrieves stored queries.
#
# GET /queries
# operationId: doubleclickbidmanager.queries.listqueries
export def "queries doubleclickbidmanagerquerieslistqueries" [
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
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of results per page. Must be between 1 and 100. Defaults to 100 if unspecified.
  --page-token: string # Optional pagination token.
]: nothing -> record<kind: string, nextPageToken: string, queries: table<kind: string, metadata: record, params: record, queryId: string, reportDataEndTimeMs: string, reportDataStartTimeMs: string, schedule: record, timezoneCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/queries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves stored reports.
#
# GET /queries/{queryId}/reports
# operationId: doubleclickbidmanager.reports.listreports
export def "queries-reports doubleclickbidmanagerreportslistreports" [
  query_id: string
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
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of results per page. Must be between 1 and 100. Defaults to 100 if unspecified.
  --page-token: string # Optional pagination token.
]: nothing -> record<kind: string, nextPageToken: string, reports: table<key: record, metadata: record, params: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query_id: $query_id} | format pattern "/queries/{query_id}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a query.
#
# POST /query
# operationId: doubleclickbidmanager.queries.createquery
# --metadata shape: {dataRange?: "CUSTOM_DATES"|"CURRENT_DAY"|"PREVIOUS_DAY"|"WEEK_TO_DATE"|"MONTH_TO_DATE"|"QUARTER_TO_DATE"|"YEAR_TO_DATE"|"PREVIOUS_WEEK"|"PREVIOUS_HALF_MONTH"|"PREVIOUS_MONTH"|"PREVIOUS_QUARTER"|"PREVIOUS_YEAR"|"LAST_7_DAYS"|"LAST_30_DAYS"|"LAST_90_DAYS"|"LAST_365_DAYS"|"ALL_TIME"|"LAST_14_DAYS"|"TYPE_NOT_SUPPORTED"|"LAST_60_DAYS", format?: "CSV"|"EXCEL_CSV"|"XLSX", googleCloudStoragePathForLatestReport?: string, googleDrivePathForLatestReport?: string, latestReportRunTimeMs?: string, locale?: string, reportCount?: int, running?: bool, sendNotification?: bool, shareEmailAddress?: list, title?: string}
# --params shape: {filters?: list, groupBys?: list, includeInviteData?: bool, metrics?: list, options?: record, type?: "TYPE_GENERAL"|"TYPE_AUDIENCE_PERFORMANCE"|"TYPE_INVENTORY_AVAILABILITY"|"TYPE_KEYWORD"|"TYPE_PIXEL_LOAD"|"TYPE_AUDIENCE_COMPOSITION"|"TYPE_CROSS_PARTNER"|"TYPE_PAGE_CATEGORY"|"TYPE_THIRD_PARTY_DATA_PROVIDER"|"TYPE_CROSS_PARTNER_THIRD_PARTY_DATA_PROVIDER"|"TYPE_CLIENT_SAFE"|"TYPE_ORDER_ID"|"TYPE_FEE"|"TYPE_CROSS_FEE"|"TYPE_ACTIVE_GRP"|"TYPE_YOUTUBE_VERTICAL"|"TYPE_COMSCORE_VCE"|"TYPE_TRUEVIEW"|"TYPE_NIELSEN_AUDIENCE_PROFILE"|"TYPE_NIELSEN_DAILY_REACH_BUILD"|"TYPE_NIELSEN_SITE"|"TYPE_REACH_AND_FREQUENCY"|"TYPE_ESTIMATED_CONVERSION"|"TYPE_VERIFICATION"|"TYPE_TRUEVIEW_IAR"|"TYPE_NIELSEN_ONLINE_GLOBAL_MARKET"|"TYPE_PETRA_NIELSEN_AUDIENCE_PROFILE"|"TYPE_PETRA_NIELSEN_DAILY_REACH_BUILD"|"TYPE_PETRA_NIELSEN_ONLINE_GLOBAL_MARKET"|"TYPE_NOT_SUPPORTED"|"TYPE_REACH_AUDIENCE"|"TYPE_LINEAR_TV_SEARCH_LIFT"|"TYPE_PATH"|"TYPE_PATH_ATTRIBUTION"}
# --schedule shape: {endTimeMs?: string, frequency?: "ONE_TIME"|"DAILY"|"WEEKLY"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"YEARLY", nextRunMinuteOfDay?: int, nextRunTimezoneCode?: string, startTimeMs?: string}
export def "query doubleclickbidmanagerqueriescreatequery" [
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
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --asynchronous: oneof<nothing, bool> # If true, tries to run the query asynchronously. Only applicable when the frequency is ONE_TIME.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "doubleclickbidmanager#query".
  --metadata: record # Query metadata. — shape: {dataRange?: "CUSTOM_DATES"|"CURRENT_DAY"|"PREVIOUS_DAY"|"WEEK_TO_DATE"|"MONTH_TO_DATE"|"QUARTER_TO_DATE"|"YEAR_TO_DATE"|"PREVIOUS_WEEK"|"PREVIOUS_HALF_MONTH"|"PREVIOUS_MONTH"|"PREVIOUS_QUARTER"|"PREVIOUS_YEAR"|"LAST_7_DAYS"|"LAST_30_DAYS"|"LAST_90_DAYS"|"LAST_365_DAYS"|"ALL_TIME"|"LAST_14_DAYS"|"TYPE_NOT_SUPPORTED"|"LAST_60_DAYS", format?: "CSV"|"EXCEL_CSV"|"XLSX", googleCloudStoragePathForLatestReport?: string, googleDrivePathForLatestReport?: string, latestReportRunTimeMs?: string, locale?: string, reportCount?: int, running?: bool, sendNotification?: bool, shareEmailAddress?: list, title?: string}
  --params: record # Parameters of a query or report. — shape: {filters?: list, groupBys?: list, includeInviteData?: bool, metrics?: list, options?: record, type?: "TYPE_GENERAL"|"TYPE_AUDIENCE_PERFORMANCE"|"TYPE_INVENTORY_AVAILABILITY"|"TYPE_KEYWORD"|"TYPE_PIXEL_LOAD"|"TYPE_AUDIENCE_COMPOSITION"|"TYPE_CROSS_PARTNER"|"TYPE_PAGE_CATEGORY"|"TYPE_THIRD_PARTY_DATA_PROVIDER"|"TYPE_CROSS_PARTNER_THIRD_PARTY_DATA_PROVIDER"|"TYPE_CLIENT_SAFE"|"TYPE_ORDER_ID"|"TYPE_FEE"|"TYPE_CROSS_FEE"|"TYPE_ACTIVE_GRP"|"TYPE_YOUTUBE_VERTICAL"|"TYPE_COMSCORE_VCE"|"TYPE_TRUEVIEW"|"TYPE_NIELSEN_AUDIENCE_PROFILE"|"TYPE_NIELSEN_DAILY_REACH_BUILD"|"TYPE_NIELSEN_SITE"|"TYPE_REACH_AND_FREQUENCY"|"TYPE_ESTIMATED_CONVERSION"|"TYPE_VERIFICATION"|"TYPE_TRUEVIEW_IAR"|"TYPE_NIELSEN_ONLINE_GLOBAL_MARKET"|"TYPE_PETRA_NIELSEN_AUDIENCE_PROFILE"|"TYPE_PETRA_NIELSEN_DAILY_REACH_BUILD"|"TYPE_PETRA_NIELSEN_ONLINE_GLOBAL_MARKET"|"TYPE_NOT_SUPPORTED"|"TYPE_REACH_AUDIENCE"|"TYPE_LINEAR_TV_SEARCH_LIFT"|"TYPE_PATH"|"TYPE_PATH_ATTRIBUTION"}
  --query-id: string # Query ID. (format: int64)
  --report-data-end-time-ms: string # The ending time for the data that is shown in the report. Note, reportDataEndTimeMs is required if metadata.dataRange is CUSTOM_DATES and ignored otherwise. (format: int64)
  --report-data-start-time-ms: string # The starting time for the data that is shown in the report. Note, reportDataStartTimeMs is required if metadata.dataRange is CUSTOM_DATES and ignored otherwise. (format: int64)
  --schedule: record # Information on how frequently and when to run a query. — shape: {endTimeMs?: string, frequency?: "ONE_TIME"|"DAILY"|"WEEKLY"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"YEARLY", nextRunMinuteOfDay?: int, nextRunTimezoneCode?: string, startTimeMs?: string}
  --timezone-code: string # Canonical timezone code for report data time. Defaults to America/New_York.
]: any -> record<kind: string, metadata: record<dataRange: string, format: string, googleCloudStoragePathForLatestReport: string, googleDrivePathForLatestReport: string, latestReportRunTimeMs: string, locale: string, reportCount: int, running: bool, sendNotification: bool, shareEmailAddress: list<string>, title: string>, params: record<filters: list<record>, groupBys: list<string>, includeInviteData: bool, metrics: list<string>, options: record<includeOnlyTargetedUserLists: bool, pathQueryOptions: record>, type: string>, queryId: string, reportDataEndTimeMs: string, reportDataStartTimeMs: string, schedule: record<endTimeMs: string, frequency: string, nextRunMinuteOfDay: int, nextRunTimezoneCode: string, startTimeMs: string>, timezoneCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "asynchronous" $asynchronous "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query" $qp)
  let body = {"kind": $kind, "metadata": $metadata, "params": $params, "queryId": $query_id, "reportDataEndTimeMs": $report_data_end_time_ms, "reportDataStartTimeMs": $report_data_start_time_ms, "schedule": $schedule, "timezoneCode": $timezone_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a stored query as well as the associated stored reports.
#
# DELETE /query/{queryId}
# operationId: doubleclickbidmanager.queries.deletequery
export def "query doubleclickbidmanagerqueriesdeletequery" [
  query_id: string
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
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query_id: $query_id} | format pattern "/query/{query_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a stored query.
#
# GET /query/{queryId}
# operationId: doubleclickbidmanager.queries.getquery
export def "query doubleclickbidmanagerqueriesgetquery" [
  query_id: string
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
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<kind: string, metadata: record<dataRange: string, format: string, googleCloudStoragePathForLatestReport: string, googleDrivePathForLatestReport: string, latestReportRunTimeMs: string, locale: string, reportCount: int, running: bool, sendNotification: bool, shareEmailAddress: list<string>, title: string>, params: record<filters: list<record>, groupBys: list<string>, includeInviteData: bool, metrics: list<string>, options: record<includeOnlyTargetedUserLists: bool, pathQueryOptions: record>, type: string>, queryId: string, reportDataEndTimeMs: string, reportDataStartTimeMs: string, schedule: record<endTimeMs: string, frequency: string, nextRunMinuteOfDay: int, nextRunTimezoneCode: string, startTimeMs: string>, timezoneCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query_id: $query_id} | format pattern "/query/{query_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs a stored query to generate a report.
#
# POST /query/{queryId}
# operationId: doubleclickbidmanager.queries.runquery
export def "query doubleclickbidmanagerqueriesrunquery" [
  query_id: string
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
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --asynchronous: oneof<nothing, bool> # If true, tries to run the query asynchronously.
  --data-range: string@data-range-completer # Report data range used to generate the report.
  --report-data-end-time-ms: string # The ending time for the data that is shown in the report. Note, reportDataEndTimeMs is required if dataRange is CUSTOM_DATES and ignored otherwise. (format: int64)
  --report-data-start-time-ms: string # The starting time for the data that is shown in the report. Note, reportDataStartTimeMs is required if dataRange is CUSTOM_DATES and ignored otherwise. (format: int64)
  --timezone-code: string # Canonical timezone code for report data time. Defaults to America/New_York.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "asynchronous" $asynchronous "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query_id: $query_id} | format pattern "/query/{query_id}") $qp)
  let body = {"dataRange": $data_range, "reportDataEndTimeMs": $report_data_end_time_ms, "reportDataStartTimeMs": $report_data_start_time_ms, "timezoneCode": $timezone_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
