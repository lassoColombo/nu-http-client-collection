# Auto-generated client for Business Profile Performance API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/businessprofileperformance/v1/openapi.json
# Auth: --token flag or $env.BUSINESS_PROFILE_PERFORMANCE_API_TOKEN

const BASE_URL = "https://businessprofileperformance.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BUSINESS_PROFILE_PERFORMANCE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://businessprofileperformance.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def daily-metric-completer [] { ["BUSINESS_BOOKINGS" "BUSINESS_CONVERSATIONS" "BUSINESS_DIRECTION_REQUESTS" "BUSINESS_FOOD_MENU_CLICKS" "BUSINESS_FOOD_ORDERS" "BUSINESS_IMPRESSIONS_DESKTOP_MAPS" "BUSINESS_IMPRESSIONS_DESKTOP_SEARCH" "BUSINESS_IMPRESSIONS_MOBILE_MAPS" "BUSINESS_IMPRESSIONS_MOBILE_SEARCH" "CALL_CLICKS" "DAILY_METRIC_UNKNOWN" "WEBSITE_CLICKS"] }
def daily-sub-entity-type-day-of-week-completer [] { ["DAY_OF_WEEK_UNSPECIFIED" "FRIDAY" "MONDAY" "SATURDAY" "SUNDAY" "THURSDAY" "TUESDAY" "WEDNESDAY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "locations get-multi-daily-metrics-time-series" } } | get name | first)
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

# Returns the values for each date from a given time range and optionally the sub entity type, where applicable, that are associated with the specific daily metrics. Example request: `GET https://businessprofileperformance.googleapis.com/v1/locations/12345:fetchMultiDailyMetricsTimeSeries?dailyMetrics=WEBSITE_CLICKS&dailyMetrics=CALL_CLICKS&daily_range.start_date.year=2022&daily_range.start_date.month=1&daily_range.start_date.day=1&daily_range.end_date.year=2022&daily_range.end_date.month=3&daily_range.end_date.day=31`
#
# GET /v1/{location}:fetchMultiDailyMetricsTimeSeries
# operationId: businessprofileperformance.locations.fetchMultiDailyMetricsTimeSeries
export def "locations get-multi-daily-metrics-time-series" [
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
  --daily-metrics: list<string> # Required. The metrics to retrieve time series for.
  --daily-range-end-date-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --daily-range-end-date-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --daily-range-end-date-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
  --daily-range-start-date-day: int # Day of a month. Must be from 1 to 31 and valid for the year and month, or 0 to specify a year by itself or a year and month where the day isn't significant.
  --daily-range-start-date-month: int # Month of a year. Must be from 1 to 12, or 0 to specify a year without a month and day.
  --daily-range-start-date-year: int # Year of the date. Must be from 1 to 9999, or 0 to specify a date without a year.
]: nothing -> record<multiDailyMetricTimeSeries: table<dailyMetricTimeSeries: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dailyMetrics" $daily_metrics "multi") (serialize-qp "dailyRange.endDate.day" $daily_range_end_date_day "scalar") (serialize-qp "dailyRange.endDate.month" $daily_range_end_date_month "scalar") (serialize-qp "dailyRange.endDate.year" $daily_range_end_date_year "scalar") (serialize-qp "dailyRange.startDate.day" $daily_range_start_date_day "scalar") (serialize-qp "dailyRange.startDate.month" $daily_range_start_date_month "scalar") (serialize-qp "dailyRange.startDate.year" $daily_range_start_date_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location)} | format pattern "/v1/{location}:fetchMultiDailyMetricsTimeSeries") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "dailyMetrics": $daily_metrics, "dailyRange.endDate.day": $daily_range_end_date_day, "dailyRange.endDate.month": $daily_range_end_date_month, "dailyRange.endDate.year": $daily_range_end_date_year, "dailyRange.startDate.day": $daily_range_start_date_day, "dailyRange.startDate.month": $daily_range_start_date_month, "dailyRange.startDate.year": $daily_range_start_date_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the values for each date from a given time range that are associated with the specific daily metric. Example request: `GET https://businessprofileperformance.googleapis.com/v1/locations/12345:getDailyMetricsTimeSeries?dailyMetric=WEBSITE_CLICKS&daily_range.start_date.year=2022&daily_range.start_date.month=1&daily_range.start_date.day=1&daily_range.end_date.year=2022&daily_range.end_date.month=3&daily_range.end_date.day=31`
#
# GET /v1/{name}:getDailyMetricsTimeSeries
# operationId: businessprofileperformance.locations.getDailyMetricsTimeSeries
export def "locations get-daily-metrics-time-series" [
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
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dailyMetric" $daily_metric "scalar") (serialize-qp "dailyRange.endDate.day" $daily_range_end_date_day "scalar") (serialize-qp "dailyRange.endDate.month" $daily_range_end_date_month "scalar") (serialize-qp "dailyRange.endDate.year" $daily_range_end_date_year "scalar") (serialize-qp "dailyRange.startDate.day" $daily_range_start_date_day "scalar") (serialize-qp "dailyRange.startDate.month" $daily_range_start_date_month "scalar") (serialize-qp "dailyRange.startDate.year" $daily_range_start_date_year "scalar") (serialize-qp "dailySubEntityType.dayOfWeek" $daily_sub_entity_type_day_of_week "scalar") (serialize-qp "dailySubEntityType.timeOfDay.hours" $daily_sub_entity_type_time_of_day_hours "scalar") (serialize-qp "dailySubEntityType.timeOfDay.minutes" $daily_sub_entity_type_time_of_day_minutes "scalar") (serialize-qp "dailySubEntityType.timeOfDay.nanos" $daily_sub_entity_type_time_of_day_nanos "scalar") (serialize-qp "dailySubEntityType.timeOfDay.seconds" $daily_sub_entity_type_time_of_day_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1/{name}:getDailyMetricsTimeSeries") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "dailyMetric": $daily_metric, "dailyRange.endDate.day": $daily_range_end_date_day, "dailyRange.endDate.month": $daily_range_end_date_month, "dailyRange.endDate.year": $daily_range_end_date_year, "dailyRange.startDate.day": $daily_range_start_date_day, "dailyRange.startDate.month": $daily_range_start_date_month, "dailyRange.startDate.year": $daily_range_start_date_year, "dailySubEntityType.dayOfWeek": $daily_sub_entity_type_day_of_week, "dailySubEntityType.timeOfDay.hours": $daily_sub_entity_type_time_of_day_hours, "dailySubEntityType.timeOfDay.minutes": $daily_sub_entity_type_time_of_day_minutes, "dailySubEntityType.timeOfDay.nanos": $daily_sub_entity_type_time_of_day_nanos, "dailySubEntityType.timeOfDay.seconds": $daily_sub_entity_type_time_of_day_seconds} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the search keywords used to find a business in search or maps. Each search keyword is accompanied by impressions which are aggregated on a monthly basis. Example request: `GET https://businessprofileperformance.googleapis.com/v1/locations/12345/searchkeywords/impressions/monthly?monthly_range.start_month.year=2022&monthly_range.start_month.month=1&monthly_range.end_month.year=2022&monthly_range.end_month.month=3`
#
# GET /v1/{parent}/searchkeywords/impressions/monthly
# operationId: businessprofileperformance.locations.searchkeywords.impressions.monthly.list
export def "searchkeywords-impressions-monthly list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "monthlyRange.endMonth.day" $monthly_range_end_month_day "scalar") (serialize-qp "monthlyRange.endMonth.month" $monthly_range_end_month_month "scalar") (serialize-qp "monthlyRange.endMonth.year" $monthly_range_end_month_year "scalar") (serialize-qp "monthlyRange.startMonth.day" $monthly_range_start_month_day "scalar") (serialize-qp "monthlyRange.startMonth.month" $monthly_range_start_month_month "scalar") (serialize-qp "monthlyRange.startMonth.year" $monthly_range_start_month_year "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1/{parent}/searchkeywords/impressions/monthly") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "monthlyRange.endMonth.day": $monthly_range_end_month_day, "monthlyRange.endMonth.month": $monthly_range_end_month_month, "monthlyRange.endMonth.year": $monthly_range_end_month_year, "monthlyRange.startMonth.day": $monthly_range_start_month_day, "monthlyRange.startMonth.month": $monthly_range_start_month_month, "monthlyRange.startMonth.year": $monthly_range_start_month_year, "pageSize": $page_size, "pageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
