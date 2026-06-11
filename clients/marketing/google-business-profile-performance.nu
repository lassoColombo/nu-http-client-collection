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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://businessprofileperformance.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def dailyMetric-completer [] { ["BUSINESS_BOOKINGS" "BUSINESS_CONVERSATIONS" "BUSINESS_DIRECTION_REQUESTS" "BUSINESS_FOOD_MENU_CLICKS" "BUSINESS_FOOD_ORDERS" "BUSINESS_IMPRESSIONS_DESKTOP_MAPS" "BUSINESS_IMPRESSIONS_DESKTOP_SEARCH" "BUSINESS_IMPRESSIONS_MOBILE_MAPS" "BUSINESS_IMPRESSIONS_MOBILE_SEARCH" "CALL_CLICKS" "DAILY_METRIC_UNKNOWN" "WEBSITE_CLICKS"] }
def dailySubEntityTypedayOfWeek-completer [] { ["DAY_OF_WEEK_UNSPECIFIED" "FRIDAY" "MONDAY" "SATURDAY" "SUNDAY" "THURSDAY" "TUESDAY" "WEDNESDAY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dailyMetrics: list # Required. The metrics to retrieve time series for.
  --dailyRangeendDateday: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --dailyRangeendDatemonth: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --dailyRangeendDateyear: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --dailyRangestartDateday: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --dailyRangestartDatemonth: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --dailyRangestartDateyear: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
]: nothing -> record<multiDailyMetricTimeSeries: table<dailyMetricTimeSeries: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "dailyMetrics" $dailyMetrics "multi") (serialize-qp "dailyRange.endDate.day" $dailyRangeendDateday "scalar") (serialize-qp "dailyRange.endDate.month" $dailyRangeendDatemonth "scalar") (serialize-qp "dailyRange.endDate.year" $dailyRangeendDateyear "scalar") (serialize-qp "dailyRange.startDate.day" $dailyRangestartDateday "scalar") (serialize-qp "dailyRange.startDate.month" $dailyRangestartDatemonth "scalar") (serialize-qp "dailyRange.startDate.year" $dailyRangestartDateyear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($location):fetchMultiDailyMetricsTimeSeries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dailyMetric: string@dailyMetric-completer # Required. The metric to retrieve time series.
  --dailyRangeendDateday: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --dailyRangeendDatemonth: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --dailyRangeendDateyear: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --dailyRangestartDateday: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --dailyRangestartDatemonth: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --dailyRangestartDateyear: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --dailySubEntityTypedayOfWeek: string@dailySubEntityTypedayOfWeek-completer # Represents the day of the week. Eg: MONDAY. Currently supported DailyMetrics = NONE.
  --dailySubEntityTypetimeOfDayhours: int # Hours of day in 24 hour format. Should be from 0 to 23. An API may choose to allow the value "24:00:00" for scenarios like business closing time.
  --dailySubEntityTypetimeOfDayminutes: int # Minutes of hour of day. Must be from 0 to 59.
  --dailySubEntityTypetimeOfDaynanos: int # Fractions of seconds in nanoseconds. Must be from 0 to 999,999,999.
  --dailySubEntityTypetimeOfDayseconds: int # Seconds of minutes of the time. Must normally be from 0 to 59. An API may allow the value 60 if it allows leap-seconds.
]: nothing -> record<timeSeries: record<datedValues: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "dailyMetric" $dailyMetric "scalar") (serialize-qp "dailyRange.endDate.day" $dailyRangeendDateday "scalar") (serialize-qp "dailyRange.endDate.month" $dailyRangeendDatemonth "scalar") (serialize-qp "dailyRange.endDate.year" $dailyRangeendDateyear "scalar") (serialize-qp "dailyRange.startDate.day" $dailyRangestartDateday "scalar") (serialize-qp "dailyRange.startDate.month" $dailyRangestartDatemonth "scalar") (serialize-qp "dailyRange.startDate.year" $dailyRangestartDateyear "scalar") (serialize-qp "dailySubEntityType.dayOfWeek" $dailySubEntityTypedayOfWeek "scalar") (serialize-qp "dailySubEntityType.timeOfDay.hours" $dailySubEntityTypetimeOfDayhours "scalar") (serialize-qp "dailySubEntityType.timeOfDay.minutes" $dailySubEntityTypetimeOfDayminutes "scalar") (serialize-qp "dailySubEntityType.timeOfDay.nanos" $dailySubEntityTypetimeOfDaynanos "scalar") (serialize-qp "dailySubEntityType.timeOfDay.seconds" $dailySubEntityTypetimeOfDayseconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):getDailyMetricsTimeSeries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --monthlyRangeendMonthday: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --monthlyRangeendMonthmonth: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --monthlyRangeendMonthyear: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --monthlyRangestartMonthday: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --monthlyRangestartMonthmonth: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --monthlyRangestartMonthyear: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --pageSize: int # Optional. The number of results requested. The default page size is 100. Page size can be set to a maximum of 100.
  --pageToken: string # Optional. A token indicating the next paginated result to be returned.
]: nothing -> record<nextPageToken: string, searchKeywordsCounts: table<insightsValue: record, searchKeyword: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "monthlyRange.endMonth.day" $monthlyRangeendMonthday "scalar") (serialize-qp "monthlyRange.endMonth.month" $monthlyRangeendMonthmonth "scalar") (serialize-qp "monthlyRange.endMonth.year" $monthlyRangeendMonthyear "scalar") (serialize-qp "monthlyRange.startMonth.day" $monthlyRangestartMonthday "scalar") (serialize-qp "monthlyRange.startMonth.month" $monthlyRangestartMonthmonth "scalar") (serialize-qp "monthlyRange.startMonth.year" $monthlyRangestartMonthyear "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/searchkeywords/impressions/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
