# Auto-generated client for Business Profile Performance API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/businessprofileperformance/v1/openapi.json
# Auth: --token flag or $env.BUSINESS_PROFILE_PERFORMANCE_API_TOKEN

const BASE_URL = "https://businessprofileperformance.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUSINESS_PROFILE_PERFORMANCE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://businessprofileperformance.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def daily-metric-completer [] { ["BUSINESS_BOOKINGS" "BUSINESS_CONVERSATIONS" "BUSINESS_DIRECTION_REQUESTS" "BUSINESS_FOOD_MENU_CLICKS" "BUSINESS_FOOD_ORDERS" "BUSINESS_IMPRESSIONS_DESKTOP_MAPS" "BUSINESS_IMPRESSIONS_DESKTOP_SEARCH" "BUSINESS_IMPRESSIONS_MOBILE_MAPS" "BUSINESS_IMPRESSIONS_MOBILE_SEARCH" "CALL_CLICKS" "DAILY_METRIC_UNKNOWN" "WEBSITE_CLICKS"] }
def daily-sub-entity-type-day-of-week-completer [] { ["DAY_OF_WEEK_UNSPECIFIED" "FRIDAY" "MONDAY" "SATURDAY" "SUNDAY" "THURSDAY" "TUESDAY" "WEDNESDAY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "locations businessprofileperformancelocationsfetchMultiDailyMetricsTimeSeries" } } | get name | first)
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

#  Returns the values for each date from a given time range and optionally the sub entity type, where applicable, that are associated with the specific daily metrics. Example request: `GET https://businessprofileperformance.googleapis.com/v1/locations/12345:fetchMultiDailyMetricsTimeSeries?dailyMetrics=WEBSITE_CLICKS&dailyMetrics=CALL_CLICKS&daily_range.start_date.year=2022&daily_range.start_date.month=1&daily_range.start_date.day=1&daily_range.end_date.year=2022&daily_range.end_date.month=3&daily_range.end_date.day=31`
#
# GET /v1/{location}:fetchMultiDailyMetricsTimeSeries
# operationId: businessprofileperformance.locations.fetchMultiDailyMetricsTimeSeries
export def "locations businessprofileperformancelocationsfetchMultiDailyMetricsTimeSeries" [
  location: string
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
  --daily-metrics: list # Required. The metrics to retrieve time series for.
  --daily-range-end-date-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --daily-range-end-date-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --daily-range-end-date-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --daily-range-start-date-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --daily-range-start-date-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --daily-range-start-date-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
]: nothing -> record<multiDailyMetricTimeSeries: table<dailyMetricTimeSeries: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dailyMetrics" $daily_metrics "multi") (serialize-qp "dailyRange.endDate.day" $daily_range_end_date_day "scalar") (serialize-qp "dailyRange.endDate.month" $daily_range_end_date_month "scalar") (serialize-qp "dailyRange.endDate.year" $daily_range_end_date_year "scalar") (serialize-qp "dailyRange.startDate.day" $daily_range_start_date_day "scalar") (serialize-qp "dailyRange.startDate.month" $daily_range_start_date_month "scalar") (serialize-qp "dailyRange.startDate.year" $daily_range_start_date_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: $location} | format pattern "/v1/{location}:fetchMultiDailyMetricsTimeSeries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

#  Returns the values for each date from a given time range that are associated with the specific daily metric. Example request: `GET https://businessprofileperformance.googleapis.com/v1/locations/12345:getDailyMetricsTimeSeries?dailyMetric=WEBSITE_CLICKS&daily_range.start_date.year=2022&daily_range.start_date.month=1&daily_range.start_date.day=1&daily_range.end_date.year=2022&daily_range.end_date.month=3&daily_range.end_date.day=31`
#
# GET /v1/{name}:getDailyMetricsTimeSeries
# operationId: businessprofileperformance.locations.getDailyMetricsTimeSeries
export def "locations businessprofileperformancelocationsgetDailyMetricsTimeSeries" [
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
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --daily-metric: string@daily-metric-completer # Required. The metric to retrieve time series.
  --daily-range-end-date-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --daily-range-end-date-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --daily-range-end-date-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --daily-range-start-date-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --daily-range-start-date-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --daily-range-start-date-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --daily-sub-entity-type-day-of-week: string@daily-sub-entity-type-day-of-week-completer # Represents the day of the week. Eg: MONDAY. Currently supported DailyMetrics = NONE.
  --daily-sub-entity-type-time-of-day-hours: int # Hours of day in 24 hour format. Should be from 0 to 23. An API may choose to allow the value "24:00:00" for scenarios like business closing time.
  --daily-sub-entity-type-time-of-day-minutes: int # Minutes of hour of day. Must be from 0 to 59.
  --daily-sub-entity-type-time-of-day-nanos: int # Fractions of seconds in nanoseconds. Must be from 0 to 999,999,999.
  --daily-sub-entity-type-time-of-day-seconds: int # Seconds of minutes of the time. Must normally be from 0 to 59. An API may allow the value 60 if it allows leap-seconds.
]: nothing -> record<timeSeries: record<datedValues: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dailyMetric" $daily_metric "scalar") (serialize-qp "dailyRange.endDate.day" $daily_range_end_date_day "scalar") (serialize-qp "dailyRange.endDate.month" $daily_range_end_date_month "scalar") (serialize-qp "dailyRange.endDate.year" $daily_range_end_date_year "scalar") (serialize-qp "dailyRange.startDate.day" $daily_range_start_date_day "scalar") (serialize-qp "dailyRange.startDate.month" $daily_range_start_date_month "scalar") (serialize-qp "dailyRange.startDate.year" $daily_range_start_date_year "scalar") (serialize-qp "dailySubEntityType.dayOfWeek" $daily_sub_entity_type_day_of_week "scalar") (serialize-qp "dailySubEntityType.timeOfDay.hours" $daily_sub_entity_type_time_of_day_hours "scalar") (serialize-qp "dailySubEntityType.timeOfDay.minutes" $daily_sub_entity_type_time_of_day_minutes "scalar") (serialize-qp "dailySubEntityType.timeOfDay.nanos" $daily_sub_entity_type_time_of_day_nanos "scalar") (serialize-qp "dailySubEntityType.timeOfDay.seconds" $daily_sub_entity_type_time_of_day_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: $name} | format pattern "/v1/{name}:getDailyMetricsTimeSeries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the search keywords used to find a business in search or maps. Each search keyword is accompanied by impressions which are aggregated on a monthly basis. Example request: `GET https://businessprofileperformance.googleapis.com/v1/locations/12345/searchkeywords/impressions/monthly?monthly_range.start_month.year=2022&monthly_range.start_month.month=1&monthly_range.end_month.year=2022&monthly_range.end_month.month=3`
#
# GET /v1/{parent}/searchkeywords/impressions/monthly
# operationId: businessprofileperformance.locations.searchkeywords.impressions.monthly.list
export def "searchkeywords-impressions-monthly businessprofileperformancelocationssearchkeywordsimpressionsmonthlylist" [
  parent: string
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
  --monthly-range-end-month-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --monthly-range-end-month-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --monthly-range-end-month-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --monthly-range-start-month-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --monthly-range-start-month-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --monthly-range-start-month-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --page-size: int # Optional. The number of results requested. The default page size is 100. Page size can be set to a maximum of 100.
  --page-token: string # Optional. A token indicating the next paginated result to be returned.
]: nothing -> record<nextPageToken: string, searchKeywordsCounts: table<insightsValue: record, searchKeyword: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "monthlyRange.endMonth.day" $monthly_range_end_month_day "scalar") (serialize-qp "monthlyRange.endMonth.month" $monthly_range_end_month_month "scalar") (serialize-qp "monthlyRange.endMonth.year" $monthly_range_end_month_year "scalar") (serialize-qp "monthlyRange.startMonth.day" $monthly_range_start_month_day "scalar") (serialize-qp "monthlyRange.startMonth.month" $monthly_range_start_month_month "scalar") (serialize-qp "monthlyRange.startMonth.year" $monthly_range_start_month_year "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v1/{parent}/searchkeywords/impressions/monthly") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
