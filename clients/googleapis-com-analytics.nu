# Auto-generated client for Google Analytics API vv3
# Source: https://api.apis.guru/v2/specs/googleapis.com/analytics/v3/openapi.json
# Auth: --token flag or $env.GOOGLE_ANALYTICS_API_TOKEN

const BASE_URL = "https://analytics.googleapis.com/analytics/v3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOOGLE_ANALYTICS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://analytics.googleapis.com/analytics/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["json"] }
def output-completer [] { ["dataTable" "json"] }
def sampling-level-completer [] { ["DEFAULT" "FASTER" "HIGHER_PRECISION"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "data-ga get" } } | get name | first)
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

# Returns Analytics data for a view (profile).
#
# GET /data/ga
# operationId: analytics.data.ga.get
export def "data-ga get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ids: string # Unique table ID for retrieving Analytics data. Table ID is of the form ga:XXXX, where XXXX is the Analytics view (profile) ID.
  --start-date: string # Start date for fetching Analytics data. Requests can specify a start date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is 7daysAgo.
  --end-date: string # End date for fetching Analytics data. Request can should specify an end date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is yesterday.
  --metrics: string # A comma-separated list of Analytics metrics. E.g., 'ga:sessions,ga:pageviews'. At least one metric must be specified.
  --dimensions: string # A comma-separated list of Analytics dimensions. E.g., 'ga:browser,ga:city'.
  --filters: string # A comma-separated list of dimension or metric filters to be applied to Analytics data.
  --include-empty-rows: oneof<nothing, bool> # The response will include empty rows if this parameter is set to true, the default is true
  --max-results: int # The maximum number of entries to include in this feed.
  --output: string@output-completer # The selected format for the response. Default format is JSON.
  --sampling-level: string@sampling-level-completer # The desired sampling level.
  --segment: string # An Analytics segment to be applied to data.
  --qp-sort: string # A comma-separated list of dimensions or metrics that determine the sort order for Analytics data.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<columnHeaders: table<columnType: string, dataType: string, name: string>, containsSampledData: bool, dataLastRefreshed: string, dataTable: record<cols: list<record>, rows: list<record>>, id: string, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, end_date: string, filters: string, ids: string, max_results: int, metrics: list<string>, samplingLevel: string, segment: string, sort: list<string>, start_date: string, start_index: int>, rows: list<list<string>>, sampleSize: string, sampleSpace: string, selfLink: string, totalResults: int, totalsForAllResults: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "start-date" $start_date "scalar") (serialize-qp "end-date" $end_date "scalar") (serialize-qp "metrics" $metrics "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "include-empty-rows" $include_empty_rows "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "output" $output "scalar") (serialize-qp "samplingLevel" $sampling_level "scalar") (serialize-qp "segment" $segment "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/ga" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns Analytics Multi-Channel Funnels data for a view (profile).
#
# GET /data/mcf
# operationId: analytics.data.mcf.get
export def "data-mcf get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ids: string # Unique table ID for retrieving Analytics data. Table ID is of the form ga:XXXX, where XXXX is the Analytics view (profile) ID.
  --start-date: string # Start date for fetching Analytics data. Requests can specify a start date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is 7daysAgo.
  --end-date: string # End date for fetching Analytics data. Requests can specify a start date formatted as YYYY-MM-DD, or as a relative date (e.g., today, yesterday, or 7daysAgo). The default value is 7daysAgo.
  --metrics: string # A comma-separated list of Multi-Channel Funnels metrics. E.g., 'mcf:totalConversions,mcf:totalConversionValue'. At least one metric must be specified.
  --dimensions: string # A comma-separated list of Multi-Channel Funnels dimensions. E.g., 'mcf:source,mcf:medium'.
  --filters: string # A comma-separated list of dimension or metric filters to be applied to the Analytics data.
  --max-results: int # The maximum number of entries to include in this feed.
  --sampling-level: string@sampling-level-completer # The desired sampling level.
  --qp-sort: string # A comma-separated list of dimensions or metrics that determine the sort order for the Analytics data.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<columnHeaders: table<columnType: string, dataType: string, name: string>, containsSampledData: bool, id: string, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, end_date: string, filters: string, ids: string, max_results: int, metrics: list<string>, samplingLevel: string, segment: string, sort: list<string>, start_date: string, start_index: int>, rows: list<list<record>>, sampleSize: string, sampleSpace: string, selfLink: string, totalResults: int, totalsForAllResults: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "start-date" $start_date "scalar") (serialize-qp "end-date" $end_date "scalar") (serialize-qp "metrics" $metrics "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "samplingLevel" $sampling_level "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/mcf" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns real time data for a view (profile).
#
# GET /data/realtime
# operationId: analytics.data.realtime.get
export def "data-realtime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ids: string # Unique table ID for retrieving real time data. Table ID is of the form ga:XXXX, where XXXX is the Analytics view (profile) ID.
  --metrics: string # A comma-separated list of real time metrics. E.g., 'rt:activeUsers'. At least one metric must be specified.
  --dimensions: string # A comma-separated list of real time dimensions. E.g., 'rt:medium,rt:city'.
  --filters: string # A comma-separated list of dimension or metric filters to be applied to real time data.
  --max-results: int # The maximum number of entries to include in this feed.
  --qp-sort: string # A comma-separated list of dimensions or metrics that determine the sort order for real time data.
]: nothing -> record<columnHeaders: table<columnType: string, dataType: string, name: string>, id: string, kind: string, profileInfo: record<accountId: string, internalWebPropertyId: string, profileId: string, profileName: string, tableId: string, webPropertyId: string>, query: record<dimensions: string, filters: string, ids: string, max_results: int, metrics: list<string>, sort: list<string>>, rows: list<list<string>>, selfLink: string, totalResults: int, totalsForAllResults: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "metrics" $metrics "scalar") (serialize-qp "dimensions" $dimensions "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/realtime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists account summaries (lightweight tree comprised of accounts/properties/profiles) to which the user has access.
#
# GET /management/accountSummaries
# operationId: analytics.management.accountSummaries.list
export def "management-account-summaries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of account summaries to include in this response, where the largest acceptable value is 1000.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<id: string, kind: string, name: string, starred: bool, webProperties: list>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/management/accountSummaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all accounts to which the user has access.
#
# GET /management/accounts
# operationId: analytics.management.accounts.list
export def "management-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of accounts to include in this response.
  --start-index: int # An index of the first account to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<childLink: record, created: string, id: string, kind: string, name: string, permissions: record, selfLink: string, starred: bool, updated: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/management/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists account-user links for a given account.
#
# GET /management/accounts/{accountId}/entityUserLinks
# operationId: analytics.management.accountUserLinks.list
export def "management-accounts-entity-user-links list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of account-user links to include in this response.
  --start-index: int # An index of the first account-user link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/management/accounts/{account_id}/entityUserLinks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Adds a new user to the given account.
#
# POST /management/accounts/{accountId}/entityUserLinks
# operationId: analytics.management.accountUserLinks.insert
# --entity shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
# --permissions shape: {local?: list<string>}
# --userRef shape: {email?: string, id?: string, kind?: string}
export def "management-accounts-entity-user-links create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/management/accounts/{account_id}/entityUserLinks") $qp)
  let req_body = {"entity": $entity, "id": $id, "kind": $kind, "permissions": $permissions, "selfLink": $self_link, "userRef": $user_ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes a user from the given account.
#
# DELETE /management/accounts/{accountId}/entityUserLinks/{linkId}
# operationId: analytics.management.accountUserLinks.delete
export def "management-accounts-entity-user-links delete" [
  account_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/entityUserLinks/{link_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates permissions for an existing user on the given account.
#
# PUT /management/accounts/{accountId}/entityUserLinks/{linkId}
# operationId: analytics.management.accountUserLinks.update
# --entity shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
# --permissions shape: {local?: list<string>}
# --userRef shape: {email?: string, id?: string, kind?: string}
export def "management-accounts-entity-user-links update" [
  account_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/entityUserLinks/{link_id}") $qp)
  let req_body = {"entity": $entity, "id": $id, "kind": $kind, "permissions": $permissions, "selfLink": $self_link, "userRef": $user_ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all filters for an account
#
# GET /management/accounts/{accountId}/filters
# operationId: analytics.management.filters.list
export def "management-accounts-filters list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of filters to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, advancedDetails: record, created: string, excludeDetails: record, id: string, includeDetails: record, kind: string, lowercaseDetails: record, name: string, parentLink: record, searchAndReplaceDetails: record, selfLink: string, type: string, updated: string, uppercaseDetails: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/management/accounts/{account_id}/filters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new filter.
#
# POST /management/accounts/{accountId}/filters
# operationId: analytics.management.filters.insert
# --advancedDetails shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
# --excludeDetails shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
# --includeDetails shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
# --lowercaseDetails shape: {field?: string, fieldIndex?: int}
# --parentLink shape: {href?: string, type?: string}
# --searchAndReplaceDetails shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
# --uppercaseDetails shape: {field?: string, fieldIndex?: int}
export def "management-accounts-filters create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this filter belongs.
  --advanced-details: record # Details for the filter of the type ADVANCED. — shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
  --exclude-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --id: string # Filter ID.
  --include-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --lowercase-details: record # Details for the filter of the type LOWER. — shape: {field?: string, fieldIndex?: int}
  --name: string # Name of this filter.
  --parent-link: record # Parent link for this filter. Points to the account to which this filter belongs. — shape: {href?: string, type?: string}
  --search-and-replace-details: record # Details for the filter of the type SEARCH_AND_REPLACE. — shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
  --type: string # Type of this filter. Possible values are INCLUDE, EXCLUDE, LOWERCASE, UPPERCASE, SEARCH_AND_REPLACE and ADVANCED.
  --uppercase-details: record # Details for the filter of the type UPPER. — shape: {field?: string, fieldIndex?: int}
]: any -> record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/management/accounts/{account_id}/filters") $qp)
  let req_body = {"accountId": $body_account_id, "advancedDetails": $advanced_details, "excludeDetails": $exclude_details, "id": $id, "includeDetails": $include_details, "lowercaseDetails": $lowercase_details, "name": $name, "parentLink": $parent_link, "searchAndReplaceDetails": $search_and_replace_details, "type": $type, "uppercaseDetails": $uppercase_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a filter.
#
# DELETE /management/accounts/{accountId}/filters/{filterId}
# operationId: analytics.management.filters.delete
export def "management-accounts-filters delete" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), filter_id: (encode-path-segment $filter_id)} | format pattern "/management/accounts/{account_id}/filters/{filter_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns filters to which the user has access.
#
# GET /management/accounts/{accountId}/filters/{filterId}
# operationId: analytics.management.filters.get
export def "management-accounts-filters get" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), filter_id: (encode-path-segment $filter_id)} | format pattern "/management/accounts/{account_id}/filters/{filter_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing filter. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/filters/{filterId}
# operationId: analytics.management.filters.patch
# --advancedDetails shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
# --excludeDetails shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
# --includeDetails shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
# --lowercaseDetails shape: {field?: string, fieldIndex?: int}
# --parentLink shape: {href?: string, type?: string}
# --searchAndReplaceDetails shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
# --uppercaseDetails shape: {field?: string, fieldIndex?: int}
export def "management-accounts-filters update-by-accountId-filterId" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this filter belongs.
  --advanced-details: record # Details for the filter of the type ADVANCED. — shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
  --exclude-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --id: string # Filter ID.
  --include-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --lowercase-details: record # Details for the filter of the type LOWER. — shape: {field?: string, fieldIndex?: int}
  --name: string # Name of this filter.
  --parent-link: record # Parent link for this filter. Points to the account to which this filter belongs. — shape: {href?: string, type?: string}
  --search-and-replace-details: record # Details for the filter of the type SEARCH_AND_REPLACE. — shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
  --type: string # Type of this filter. Possible values are INCLUDE, EXCLUDE, LOWERCASE, UPPERCASE, SEARCH_AND_REPLACE and ADVANCED.
  --uppercase-details: record # Details for the filter of the type UPPER. — shape: {field?: string, fieldIndex?: int}
]: any -> record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), filter_id: (encode-path-segment $filter_id)} | format pattern "/management/accounts/{account_id}/filters/{filter_id}") $qp)
  let req_body = {"accountId": $body_account_id, "advancedDetails": $advanced_details, "excludeDetails": $exclude_details, "id": $id, "includeDetails": $include_details, "lowercaseDetails": $lowercase_details, "name": $name, "parentLink": $parent_link, "searchAndReplaceDetails": $search_and_replace_details, "type": $type, "uppercaseDetails": $uppercase_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing filter.
#
# PUT /management/accounts/{accountId}/filters/{filterId}
# operationId: analytics.management.filters.update
# --advancedDetails shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
# --excludeDetails shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
# --includeDetails shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
# --lowercaseDetails shape: {field?: string, fieldIndex?: int}
# --parentLink shape: {href?: string, type?: string}
# --searchAndReplaceDetails shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
# --uppercaseDetails shape: {field?: string, fieldIndex?: int}
export def "management-accounts-filters update-by-accountId-filterId-1" [
  account_id: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this filter belongs.
  --advanced-details: record # Details for the filter of the type ADVANCED. — shape: {caseSensitive?: bool, extractA?: string, extractB?: string, fieldA?: string, fieldAIndex?: int, fieldARequired?: bool, fieldB?: string, fieldBIndex?: int, fieldBRequired?: bool, outputConstructor?: string, outputToField?: string, outputToFieldIndex?: int, overrideOutputField?: bool}
  --exclude-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --id: string # Filter ID.
  --include-details: record # JSON template for an Analytics filter expression. — shape: {caseSensitive?: bool, expressionValue?: string, field?: string, fieldIndex?: int, kind?: string, matchType?: string}
  --lowercase-details: record # Details for the filter of the type LOWER. — shape: {field?: string, fieldIndex?: int}
  --name: string # Name of this filter.
  --parent-link: record # Parent link for this filter. Points to the account to which this filter belongs. — shape: {href?: string, type?: string}
  --search-and-replace-details: record # Details for the filter of the type SEARCH_AND_REPLACE. — shape: {caseSensitive?: bool, field?: string, fieldIndex?: int, replaceString?: string, searchString?: string}
  --type: string # Type of this filter. Possible values are INCLUDE, EXCLUDE, LOWERCASE, UPPERCASE, SEARCH_AND_REPLACE and ADVANCED.
  --uppercase-details: record # Details for the filter of the type UPPER. — shape: {field?: string, fieldIndex?: int}
]: any -> record<accountId: string, advancedDetails: record<caseSensitive: bool, extractA: string, extractB: string, fieldA: string, fieldAIndex: int, fieldARequired: bool, fieldB: string, fieldBIndex: int, fieldBRequired: bool, outputConstructor: string, outputToField: string, outputToFieldIndex: int, overrideOutputField: bool>, created: string, excludeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, id: string, includeDetails: record<caseSensitive: bool, expressionValue: string, field: string, fieldIndex: int, kind: string, matchType: string>, kind: string, lowercaseDetails: record<field: string, fieldIndex: int>, name: string, parentLink: record<href: string, type: string>, searchAndReplaceDetails: record<caseSensitive: bool, field: string, fieldIndex: int, replaceString: string, searchString: string>, selfLink: string, type: string, updated: string, uppercaseDetails: record<field: string, fieldIndex: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), filter_id: (encode-path-segment $filter_id)} | format pattern "/management/accounts/{account_id}/filters/{filter_id}") $qp)
  let req_body = {"accountId": $body_account_id, "advancedDetails": $advanced_details, "excludeDetails": $exclude_details, "id": $id, "includeDetails": $include_details, "lowercaseDetails": $lowercase_details, "name": $name, "parentLink": $parent_link, "searchAndReplaceDetails": $search_and_replace_details, "type": $type, "uppercaseDetails": $uppercase_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists web properties to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties
# operationId: analytics.management.webproperties.list
export def "management-accounts-webproperties list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of web properties to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, childLink: record, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record, permissions: record, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/management/accounts/{account_id}/webproperties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new property if the account has fewer than 20 properties. Web properties are visible in the Google Analytics interface only if they have at least one profile.
#
# POST /management/accounts/{accountId}/webproperties
# operationId: analytics.management.webproperties.insert
# --childLink shape: {href?: string, type?: string}
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties create" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this web property belongs.
  --child-link: record # Child link for this web property. Points to the list of views (profiles) for this web property. — shape: {href?: string, type?: string}
  --data-retention-reset-on-new-activity: oneof<nothing, bool> # Set to true to reset the retention period of the user identifier with each new event from that user (thus setting the expiration date to current time plus retention period). Set to false to delete data associated with the user identifier automatically after the rentention period. This property cannot be set on insert.
  --data-retention-ttl: string # The length of time for which user and event data is retained. This property cannot be set on insert.
  --default-profile-id: string # Default view (profile) ID. (format: int64)
  --id: string # Web property ID of the form UA-XXXXX-YY.
  --industry-vertical: string # The industry vertical/category selected for this web property.
  --name: string # Name of this web property.
  --parent-link: record # Parent link for this web property. Points to the account to which this web property belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this web property.
  --starred: oneof<nothing, bool> # Indicates whether this web property is starred or not.
  --website-url: string # Website url for this web property.
]: any -> record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/management/accounts/{account_id}/webproperties") $qp)
  let req_body = {"accountId": $body_account_id, "childLink": $child_link, "dataRetentionResetOnNewActivity": $data_retention_reset_on_new_activity, "dataRetentionTtl": $data_retention_ttl, "defaultProfileId": $default_profile_id, "id": $id, "industryVertical": $industry_vertical, "name": $name, "parentLink": $parent_link, "permissions": $permissions, "starred": $starred, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a web property to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}
# operationId: analytics.management.webproperties.get
export def "management-accounts-webproperties get" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing web property. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}
# operationId: analytics.management.webproperties.patch
# --childLink shape: {href?: string, type?: string}
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties update-by-accountId-webPropertyId" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this web property belongs.
  --child-link: record # Child link for this web property. Points to the list of views (profiles) for this web property. — shape: {href?: string, type?: string}
  --data-retention-reset-on-new-activity: oneof<nothing, bool> # Set to true to reset the retention period of the user identifier with each new event from that user (thus setting the expiration date to current time plus retention period). Set to false to delete data associated with the user identifier automatically after the rentention period. This property cannot be set on insert.
  --data-retention-ttl: string # The length of time for which user and event data is retained. This property cannot be set on insert.
  --default-profile-id: string # Default view (profile) ID. (format: int64)
  --id: string # Web property ID of the form UA-XXXXX-YY.
  --industry-vertical: string # The industry vertical/category selected for this web property.
  --name: string # Name of this web property.
  --parent-link: record # Parent link for this web property. Points to the account to which this web property belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this web property.
  --starred: oneof<nothing, bool> # Indicates whether this web property is starred or not.
  --website-url: string # Website url for this web property.
]: any -> record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}") $qp)
  let req_body = {"accountId": $body_account_id, "childLink": $child_link, "dataRetentionResetOnNewActivity": $data_retention_reset_on_new_activity, "dataRetentionTtl": $data_retention_ttl, "defaultProfileId": $default_profile_id, "id": $id, "industryVertical": $industry_vertical, "name": $name, "parentLink": $parent_link, "permissions": $permissions, "starred": $starred, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing web property.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}
# operationId: analytics.management.webproperties.update
# --childLink shape: {href?: string, type?: string}
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties update-by-accountId-webPropertyId-1" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this web property belongs.
  --child-link: record # Child link for this web property. Points to the list of views (profiles) for this web property. — shape: {href?: string, type?: string}
  --data-retention-reset-on-new-activity: oneof<nothing, bool> # Set to true to reset the retention period of the user identifier with each new event from that user (thus setting the expiration date to current time plus retention period). Set to false to delete data associated with the user identifier automatically after the rentention period. This property cannot be set on insert.
  --data-retention-ttl: string # The length of time for which user and event data is retained. This property cannot be set on insert.
  --default-profile-id: string # Default view (profile) ID. (format: int64)
  --id: string # Web property ID of the form UA-XXXXX-YY.
  --industry-vertical: string # The industry vertical/category selected for this web property.
  --name: string # Name of this web property.
  --parent-link: record # Parent link for this web property. Points to the account to which this web property belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this web property.
  --starred: oneof<nothing, bool> # Indicates whether this web property is starred or not.
  --website-url: string # Website url for this web property.
]: any -> record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}") $qp)
  let req_body = {"accountId": $body_account_id, "childLink": $child_link, "dataRetentionResetOnNewActivity": $data_retention_reset_on_new_activity, "dataRetentionTtl": $data_retention_ttl, "defaultProfileId": $default_profile_id, "id": $id, "industryVertical": $industry_vertical, "name": $name, "parentLink": $parent_link, "permissions": $permissions, "starred": $starred, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List custom data sources to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources
# operationId: analytics.management.customDataSources.list
export def "management-accounts-webproperties-custom-data-sources list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of custom data sources to include in this response.
  --start-index: int # A 1-based index of the first custom data source to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, childLink: record, created: string, description: string, id: string, importBehavior: string, kind: string, name: string, parentLink: record, profilesLinked: list, schema: list, selfLink: string, type: string, updated: string, uploadType: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDataSources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete data associated with a previous upload.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/deleteUploadData
# operationId: analytics.management.uploads.deleteUploadData
export def "management-accounts-webproperties-custom-data-sources-delete-upload-data delete" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --custom-data-import-uids: list<string> # A list of upload UIDs.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_data_source_id: (encode-path-segment $custom_data_source_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDataSources/{custom_data_source_id}/deleteUploadData") $qp)
  let req_body = {"customDataImportUids": $custom_data_import_uids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List uploads to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads
# operationId: analytics.management.uploads.list
export def "management-accounts-webproperties-custom-data-sources-uploads list" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of uploads to include in this response.
  --start-index: int # A 1-based index of the first upload to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, customDataSourceId: string, errors: list, id: string, kind: string, status: string, uploadTime: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_data_source_id: (encode-path-segment $custom_data_source_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDataSources/{custom_data_source_id}/uploads") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload data for a custom data source.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads
# operationId: analytics.management.uploads.uploadData
export def "management-accounts-webproperties-custom-data-sources-uploads upload" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, customDataSourceId: string, errors: list<string>, id: string, kind: string, status: string, uploadTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_data_source_id: (encode-path-segment $custom_data_source_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDataSources/{custom_data_source_id}/uploads") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List uploads to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDataSources/{customDataSourceId}/uploads/{uploadId}
# operationId: analytics.management.uploads.get
export def "management-accounts-webproperties-custom-data-sources-uploads get" [
  account_id: string
  web_property_id: string
  custom_data_source_id: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, customDataSourceId: string, errors: list<string>, id: string, kind: string, status: string, uploadTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_data_source_id: (encode-path-segment $custom_data_source_id), upload_id: (encode-path-segment $upload_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDataSources/{custom_data_source_id}/uploads/{upload_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists custom dimensions to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions
# operationId: analytics.management.customDimensions.list
export def "management-accounts-webproperties-custom-dimensions list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of custom dimensions to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record, scope: string, selfLink: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDimensions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new custom dimension.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions
# operationId: analytics.management.customDimensions.insert
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-custom-dimensions create" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID.
  --active: oneof<nothing, bool> # Boolean indicating whether the custom dimension is active.
  --id: string # Custom dimension ID.
  --name: string # Name of the custom dimension.
  --parent-link: record # Parent link for the custom dimension. Points to the property to which the custom dimension belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom dimension: HIT, SESSION, USER or PRODUCT.
  --body-web-property-id: string # Property ID.
]: any -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDimensions") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "id": $id, "name": $name, "parentLink": $parent_link, "scope": $scope, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a custom dimension to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}
# operationId: analytics.management.customDimensions.get
export def "management-accounts-webproperties-custom-dimensions get" [
  account_id: string
  web_property_id: string
  custom_dimension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_dimension_id: (encode-path-segment $custom_dimension_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDimensions/{custom_dimension_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing custom dimension. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}
# operationId: analytics.management.customDimensions.patch
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-custom-dimensions update-by-accountId-webPropertyId-customDimensionId" [
  account_id: string
  web_property_id: string
  custom_dimension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom dimension being linked to a custom data source / data set.
  --body-account-id: string # Account ID.
  --active: oneof<nothing, bool> # Boolean indicating whether the custom dimension is active.
  --id: string # Custom dimension ID.
  --name: string # Name of the custom dimension.
  --parent-link: record # Parent link for the custom dimension. Points to the property to which the custom dimension belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom dimension: HIT, SESSION, USER or PRODUCT.
  --body-web-property-id: string # Property ID.
]: any -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ignoreCustomDataSourceLinks" $ignore_custom_data_source_links "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_dimension_id: (encode-path-segment $custom_dimension_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDimensions/{custom_dimension_id}") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "id": $id, "name": $name, "parentLink": $parent_link, "scope": $scope, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing custom dimension.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/customDimensions/{customDimensionId}
# operationId: analytics.management.customDimensions.update
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-custom-dimensions update-by-accountId-webPropertyId-customDimensionId-1" [
  account_id: string
  web_property_id: string
  custom_dimension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom dimension being linked to a custom data source / data set.
  --body-account-id: string # Account ID.
  --active: oneof<nothing, bool> # Boolean indicating whether the custom dimension is active.
  --id: string # Custom dimension ID.
  --name: string # Name of the custom dimension.
  --parent-link: record # Parent link for the custom dimension. Points to the property to which the custom dimension belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom dimension: HIT, SESSION, USER or PRODUCT.
  --body-web-property-id: string # Property ID.
]: any -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ignoreCustomDataSourceLinks" $ignore_custom_data_source_links "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_dimension_id: (encode-path-segment $custom_dimension_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customDimensions/{custom_dimension_id}") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "id": $id, "name": $name, "parentLink": $parent_link, "scope": $scope, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists custom metrics to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics
# operationId: analytics.management.customMetrics.list
export def "management-accounts-webproperties-custom-metrics list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of custom metrics to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customMetrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new custom metric.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics
# operationId: analytics.management.customMetrics.insert
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-custom-metrics create" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID.
  --active: oneof<nothing, bool> # Boolean indicating whether the custom metric is active.
  --id: string # Custom metric ID.
  --max-value: string # Max value of custom metric.
  --min-value: string # Min value of custom metric.
  --name: string # Name of the custom metric.
  --parent-link: record # Parent link for the custom metric. Points to the property to which the custom metric belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom metric: HIT or PRODUCT.
  --type: string # Data type of custom metric.
  --body-web-property-id: string # Property ID.
]: any -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customMetrics") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "id": $id, "max_value": $max_value, "min_value": $min_value, "name": $name, "parentLink": $parent_link, "scope": $scope, "type": $type, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a custom metric to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}
# operationId: analytics.management.customMetrics.get
export def "management-accounts-webproperties-custom-metrics get" [
  account_id: string
  web_property_id: string
  custom_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_metric_id: (encode-path-segment $custom_metric_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customMetrics/{custom_metric_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing custom metric. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}
# operationId: analytics.management.customMetrics.patch
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-custom-metrics update-by-accountId-webPropertyId-customMetricId" [
  account_id: string
  web_property_id: string
  custom_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom metric being linked to a custom data source / data set.
  --body-account-id: string # Account ID.
  --active: oneof<nothing, bool> # Boolean indicating whether the custom metric is active.
  --id: string # Custom metric ID.
  --max-value: string # Max value of custom metric.
  --min-value: string # Min value of custom metric.
  --name: string # Name of the custom metric.
  --parent-link: record # Parent link for the custom metric. Points to the property to which the custom metric belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom metric: HIT or PRODUCT.
  --type: string # Data type of custom metric.
  --body-web-property-id: string # Property ID.
]: any -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ignoreCustomDataSourceLinks" $ignore_custom_data_source_links "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_metric_id: (encode-path-segment $custom_metric_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customMetrics/{custom_metric_id}") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "id": $id, "max_value": $max_value, "min_value": $min_value, "name": $name, "parentLink": $parent_link, "scope": $scope, "type": $type, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing custom metric.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/customMetrics/{customMetricId}
# operationId: analytics.management.customMetrics.update
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-custom-metrics update-by-accountId-webPropertyId-customMetricId-1" [
  account_id: string
  web_property_id: string
  custom_metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ignore-custom-data-source-links: oneof<nothing, bool> # Force the update and ignore any warnings related to the custom metric being linked to a custom data source / data set.
  --body-account-id: string # Account ID.
  --active: oneof<nothing, bool> # Boolean indicating whether the custom metric is active.
  --id: string # Custom metric ID.
  --max-value: string # Max value of custom metric.
  --min-value: string # Min value of custom metric.
  --name: string # Name of the custom metric.
  --parent-link: record # Parent link for the custom metric. Points to the property to which the custom metric belongs. — shape: {href?: string, type?: string}
  --scope: string # Scope of the custom metric: HIT or PRODUCT.
  --type: string # Data type of custom metric.
  --body-web-property-id: string # Property ID.
]: any -> record<accountId: string, active: bool, created: string, id: string, index: int, kind: string, max_value: string, min_value: string, name: string, parentLink: record<href: string, type: string>, scope: string, selfLink: string, type: string, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "ignoreCustomDataSourceLinks" $ignore_custom_data_source_links "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), custom_metric_id: (encode-path-segment $custom_metric_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/customMetrics/{custom_metric_id}") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "id": $id, "max_value": $max_value, "min_value": $min_value, "name": $name, "parentLink": $parent_link, "scope": $scope, "type": $type, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists webProperty-Google Ads links for a given web property.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks
# operationId: analytics.management.webPropertyAdWordsLinks.list
export def "management-accounts-webproperties-entity-ad-words-links list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of webProperty-Google Ads links to include in this response.
  --start-index: int # An index of the first webProperty-Google Ads link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<adWordsAccounts: list, entity: record, id: string, kind: string, name: string, profileIds: list, selfLink: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityAdWordsLinks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a webProperty-Google Ads link.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks
# operationId: analytics.management.webPropertyAdWordsLinks.insert
# --adWordsAccounts item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
# --entity shape: {webPropertyRef?: record}
export def "management-accounts-webproperties-entity-ad-words-links create" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ad-words-accounts: list # A list of Google Ads client accounts. These cannot be MCC accounts. This field is required when creating a Google Ads link. It cannot be empty. — item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
  --entity: record # Web property being linked. — shape: {webPropertyRef?: record}
  --id: string # Entity Google Ads link ID
  --kind: string # Resource type for entity Google Ads link. (default: analytics#entityAdWordsLink)
  --name: string # Name of the link. This field is required when creating a Google Ads link.
  --profile-ids: list<string> # IDs of linked Views (Profiles) represented as strings.
  --self-link: string # URL link for this Google Analytics - Google Ads link.
]: any -> record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityAdWordsLinks") $qp)
  let req_body = {"adWordsAccounts": $ad_words_accounts, "entity": $entity, "id": $id, "kind": $kind, "name": $name, "profileIds": $profile_ids, "selfLink": $self_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a web property-Google Ads link.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# operationId: analytics.management.webPropertyAdWordsLinks.delete
export def "management-accounts-webproperties-entity-ad-words-links delete" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), web_property_ad_words_link_id: (encode-path-segment $web_property_ad_words_link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityAdWordsLinks/{web_property_ad_words_link_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a web property-Google Ads link to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# operationId: analytics.management.webPropertyAdWordsLinks.get
export def "management-accounts-webproperties-entity-ad-words-links get" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), web_property_ad_words_link_id: (encode-path-segment $web_property_ad_words_link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityAdWordsLinks/{web_property_ad_words_link_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing webProperty-Google Ads link. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# operationId: analytics.management.webPropertyAdWordsLinks.patch
# --adWordsAccounts item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
# --entity shape: {webPropertyRef?: record}
export def "management-accounts-webproperties-entity-ad-words-links update-by-accountId-webPropertyId-webPropertyAdWordsLinkId" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ad-words-accounts: list # A list of Google Ads client accounts. These cannot be MCC accounts. This field is required when creating a Google Ads link. It cannot be empty. — item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
  --entity: record # Web property being linked. — shape: {webPropertyRef?: record}
  --id: string # Entity Google Ads link ID
  --kind: string # Resource type for entity Google Ads link. (default: analytics#entityAdWordsLink)
  --name: string # Name of the link. This field is required when creating a Google Ads link.
  --profile-ids: list<string> # IDs of linked Views (Profiles) represented as strings.
  --self-link: string # URL link for this Google Analytics - Google Ads link.
]: any -> record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), web_property_ad_words_link_id: (encode-path-segment $web_property_ad_words_link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityAdWordsLinks/{web_property_ad_words_link_id}") $qp)
  let req_body = {"adWordsAccounts": $ad_words_accounts, "entity": $entity, "id": $id, "kind": $kind, "name": $name, "profileIds": $profile_ids, "selfLink": $self_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing webProperty-Google Ads link.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/entityAdWordsLinks/{webPropertyAdWordsLinkId}
# operationId: analytics.management.webPropertyAdWordsLinks.update
# --adWordsAccounts item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
# --entity shape: {webPropertyRef?: record}
export def "management-accounts-webproperties-entity-ad-words-links update-by-accountId-webPropertyId-webPropertyAdWordsLinkId-1" [
  account_id: string
  web_property_id: string
  web_property_ad_words_link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --ad-words-accounts: list # A list of Google Ads client accounts. These cannot be MCC accounts. This field is required when creating a Google Ads link. It cannot be empty. — item shape: {autoTaggingEnabled?: bool, customerId?: string, kind?: string}
  --entity: record # Web property being linked. — shape: {webPropertyRef?: record}
  --id: string # Entity Google Ads link ID
  --kind: string # Resource type for entity Google Ads link. (default: analytics#entityAdWordsLink)
  --name: string # Name of the link. This field is required when creating a Google Ads link.
  --profile-ids: list<string> # IDs of linked Views (Profiles) represented as strings.
  --self-link: string # URL link for this Google Analytics - Google Ads link.
]: any -> record<adWordsAccounts: table<autoTaggingEnabled: bool, customerId: string, kind: string>, entity: record<webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, name: string, profileIds: list<string>, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), web_property_ad_words_link_id: (encode-path-segment $web_property_ad_words_link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityAdWordsLinks/{web_property_ad_words_link_id}") $qp)
  let req_body = {"adWordsAccounts": $ad_words_accounts, "entity": $entity, "id": $id, "kind": $kind, "name": $name, "profileIds": $profile_ids, "selfLink": $self_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists webProperty-user links for a given web property.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks
# operationId: analytics.management.webpropertyUserLinks.list
export def "management-accounts-webproperties-entity-user-links list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of webProperty-user Links to include in this response.
  --start-index: int # An index of the first webProperty-user link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityUserLinks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Adds a new user to the given web property.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks
# operationId: analytics.management.webpropertyUserLinks.insert
# --entity shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
# --permissions shape: {local?: list<string>}
# --userRef shape: {email?: string, id?: string, kind?: string}
export def "management-accounts-webproperties-entity-user-links create" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityUserLinks") $qp)
  let req_body = {"entity": $entity, "id": $id, "kind": $kind, "permissions": $permissions, "selfLink": $self_link, "userRef": $user_ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes a user from the given web property.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks/{linkId}
# operationId: analytics.management.webpropertyUserLinks.delete
export def "management-accounts-webproperties-entity-user-links delete" [
  account_id: string
  web_property_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityUserLinks/{link_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates permissions for an existing user on the given web property.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/entityUserLinks/{linkId}
# operationId: analytics.management.webpropertyUserLinks.update
# --entity shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
# --permissions shape: {local?: list<string>}
# --userRef shape: {email?: string, id?: string, kind?: string}
export def "management-accounts-webproperties-entity-user-links update" [
  account_id: string
  web_property_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/entityUserLinks/{link_id}") $qp)
  let req_body = {"entity": $entity, "id": $id, "kind": $kind, "permissions": $permissions, "selfLink": $self_link, "userRef": $user_ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists views (profiles) to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles
# operationId: analytics.management.profiles.list
export def "management-accounts-webproperties-profiles list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of views (profiles) to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, botFilteringEnabled: bool, childLink: record, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record, permissions: record, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new view (profile).
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles
# operationId: analytics.management.profiles.insert
# --childLink shape: {href?: string, type?: string}
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-profiles create" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this view (profile) belongs.
  --bot-filtering-enabled: oneof<nothing, bool> # Indicates whether bot filtering is enabled for this view (profile).
  --child-link: record # Child link for this view (profile). Points to the list of goals for this view (profile). — shape: {href?: string, type?: string}
  --currency: string # The currency type associated with this view (profile), defaults to USD. The supported values are: USD, JPY, EUR, GBP, AUD, KRW, BRL, CNY, DKK, RUB, SEK, NOK, PLN, TRY, TWD, HKD, THB, IDR, ARS, MXN, VND, PHP, INR, CHF, CAD, CZK, NZD, HUF, BGN, LTL, ZAR, UAH, AED, BOB, CLP, COP, EGP, HRK, ILS, MAD, MYR, PEN, PKR, RON, RSD, SAR, SGD, VEF, LVL
  --default-page: string # Default page for this view (profile).
  --e-commerce-tracking: oneof<nothing, bool> # Indicates whether ecommerce tracking is enabled for this view (profile).
  --enhanced-e-commerce-tracking: oneof<nothing, bool> # Indicates whether enhanced ecommerce tracking is enabled for this view (profile). This property can only be enabled if ecommerce tracking is enabled.
  --exclude-query-parameters: string # The query parameters that are excluded from this view (profile).
  --id: string # View (Profile) ID.
  --name: string # Name of this view (profile).
  --parent-link: record # Parent link for this view (profile). Points to the web property to which this view (profile) belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this view (profile).
  --site-search-category-parameters: string # Site search category parameters for this view (profile).
  --site-search-query-parameters: string # The site search query parameters for this view (profile).
  --starred: oneof<nothing, bool> # Indicates whether this view (profile) is starred or not.
  --strip-site-search-category-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search category parameters from the URLs in your reports.
  --strip-site-search-query-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search query parameters from the URLs in your reports.
  --timezone: string # Time zone for which this view (profile) has been configured. Time zones are identified by strings from the TZ database.
  --type: string # View (Profile) type. Supported types: WEB or APP.
  --website-url: string # Website URL for this view (profile).
]: any -> record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles") $qp)
  let req_body = {"accountId": $body_account_id, "botFilteringEnabled": $bot_filtering_enabled, "childLink": $child_link, "currency": $currency, "defaultPage": $default_page, "eCommerceTracking": $e_commerce_tracking, "enhancedECommerceTracking": $enhanced_e_commerce_tracking, "excludeQueryParameters": $exclude_query_parameters, "id": $id, "name": $name, "parentLink": $parent_link, "permissions": $permissions, "siteSearchCategoryParameters": $site_search_category_parameters, "siteSearchQueryParameters": $site_search_query_parameters, "starred": $starred, "stripSiteSearchCategoryParameters": $strip_site_search_category_parameters, "stripSiteSearchQueryParameters": $strip_site_search_query_parameters, "timezone": $timezone, "type": $type, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a view (profile).
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# operationId: analytics.management.profiles.delete
export def "management-accounts-webproperties-profiles delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a view (profile) to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# operationId: analytics.management.profiles.get
export def "management-accounts-webproperties-profiles get" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing view (profile). This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# operationId: analytics.management.profiles.patch
# --childLink shape: {href?: string, type?: string}
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-profiles update-by-accountId-webPropertyId-profileId" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this view (profile) belongs.
  --bot-filtering-enabled: oneof<nothing, bool> # Indicates whether bot filtering is enabled for this view (profile).
  --child-link: record # Child link for this view (profile). Points to the list of goals for this view (profile). — shape: {href?: string, type?: string}
  --currency: string # The currency type associated with this view (profile), defaults to USD. The supported values are: USD, JPY, EUR, GBP, AUD, KRW, BRL, CNY, DKK, RUB, SEK, NOK, PLN, TRY, TWD, HKD, THB, IDR, ARS, MXN, VND, PHP, INR, CHF, CAD, CZK, NZD, HUF, BGN, LTL, ZAR, UAH, AED, BOB, CLP, COP, EGP, HRK, ILS, MAD, MYR, PEN, PKR, RON, RSD, SAR, SGD, VEF, LVL
  --default-page: string # Default page for this view (profile).
  --e-commerce-tracking: oneof<nothing, bool> # Indicates whether ecommerce tracking is enabled for this view (profile).
  --enhanced-e-commerce-tracking: oneof<nothing, bool> # Indicates whether enhanced ecommerce tracking is enabled for this view (profile). This property can only be enabled if ecommerce tracking is enabled.
  --exclude-query-parameters: string # The query parameters that are excluded from this view (profile).
  --id: string # View (Profile) ID.
  --name: string # Name of this view (profile).
  --parent-link: record # Parent link for this view (profile). Points to the web property to which this view (profile) belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this view (profile).
  --site-search-category-parameters: string # Site search category parameters for this view (profile).
  --site-search-query-parameters: string # The site search query parameters for this view (profile).
  --starred: oneof<nothing, bool> # Indicates whether this view (profile) is starred or not.
  --strip-site-search-category-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search category parameters from the URLs in your reports.
  --strip-site-search-query-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search query parameters from the URLs in your reports.
  --timezone: string # Time zone for which this view (profile) has been configured. Time zones are identified by strings from the TZ database.
  --type: string # View (Profile) type. Supported types: WEB or APP.
  --website-url: string # Website URL for this view (profile).
]: any -> record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}") $qp)
  let req_body = {"accountId": $body_account_id, "botFilteringEnabled": $bot_filtering_enabled, "childLink": $child_link, "currency": $currency, "defaultPage": $default_page, "eCommerceTracking": $e_commerce_tracking, "enhancedECommerceTracking": $enhanced_e_commerce_tracking, "excludeQueryParameters": $exclude_query_parameters, "id": $id, "name": $name, "parentLink": $parent_link, "permissions": $permissions, "siteSearchCategoryParameters": $site_search_category_parameters, "siteSearchQueryParameters": $site_search_query_parameters, "starred": $starred, "stripSiteSearchCategoryParameters": $strip_site_search_category_parameters, "stripSiteSearchQueryParameters": $strip_site_search_query_parameters, "timezone": $timezone, "type": $type, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing view (profile).
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}
# operationId: analytics.management.profiles.update
# --childLink shape: {href?: string, type?: string}
# --parentLink shape: {href?: string, type?: string}
export def "management-accounts-webproperties-profiles update-by-accountId-webPropertyId-profileId-1" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this view (profile) belongs.
  --bot-filtering-enabled: oneof<nothing, bool> # Indicates whether bot filtering is enabled for this view (profile).
  --child-link: record # Child link for this view (profile). Points to the list of goals for this view (profile). — shape: {href?: string, type?: string}
  --currency: string # The currency type associated with this view (profile), defaults to USD. The supported values are: USD, JPY, EUR, GBP, AUD, KRW, BRL, CNY, DKK, RUB, SEK, NOK, PLN, TRY, TWD, HKD, THB, IDR, ARS, MXN, VND, PHP, INR, CHF, CAD, CZK, NZD, HUF, BGN, LTL, ZAR, UAH, AED, BOB, CLP, COP, EGP, HRK, ILS, MAD, MYR, PEN, PKR, RON, RSD, SAR, SGD, VEF, LVL
  --default-page: string # Default page for this view (profile).
  --e-commerce-tracking: oneof<nothing, bool> # Indicates whether ecommerce tracking is enabled for this view (profile).
  --enhanced-e-commerce-tracking: oneof<nothing, bool> # Indicates whether enhanced ecommerce tracking is enabled for this view (profile). This property can only be enabled if ecommerce tracking is enabled.
  --exclude-query-parameters: string # The query parameters that are excluded from this view (profile).
  --id: string # View (Profile) ID.
  --name: string # Name of this view (profile).
  --parent-link: record # Parent link for this view (profile). Points to the web property to which this view (profile) belongs. — shape: {href?: string, type?: string}
  --permissions: record # Permissions the user has for this view (profile).
  --site-search-category-parameters: string # Site search category parameters for this view (profile).
  --site-search-query-parameters: string # The site search query parameters for this view (profile).
  --starred: oneof<nothing, bool> # Indicates whether this view (profile) is starred or not.
  --strip-site-search-category-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search category parameters from the URLs in your reports.
  --strip-site-search-query-parameters: oneof<nothing, bool> # Whether or not Analytics will strip search query parameters from the URLs in your reports.
  --timezone: string # Time zone for which this view (profile) has been configured. Time zones are identified by strings from the TZ database.
  --type: string # View (Profile) type. Supported types: WEB or APP.
  --website-url: string # Website URL for this view (profile).
]: any -> record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list<string>>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}") $qp)
  let req_body = {"accountId": $body_account_id, "botFilteringEnabled": $bot_filtering_enabled, "childLink": $child_link, "currency": $currency, "defaultPage": $default_page, "eCommerceTracking": $e_commerce_tracking, "enhancedECommerceTracking": $enhanced_e_commerce_tracking, "excludeQueryParameters": $exclude_query_parameters, "id": $id, "name": $name, "parentLink": $parent_link, "permissions": $permissions, "siteSearchCategoryParameters": $site_search_category_parameters, "siteSearchQueryParameters": $site_search_query_parameters, "starred": $starred, "stripSiteSearchCategoryParameters": $strip_site_search_category_parameters, "stripSiteSearchQueryParameters": $strip_site_search_query_parameters, "timezone": $timezone, "type": $type, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists profile-user links for a given view (profile).
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks
# operationId: analytics.management.profileUserLinks.list
export def "management-accounts-webproperties-profiles-entity-user-links list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of profile-user links to include in this response.
  --start-index: int # An index of the first profile-user link to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<entity: record, id: string, kind: string, permissions: record, selfLink: string, userRef: record>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/entityUserLinks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Adds a new user to the given view (profile).
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks
# operationId: analytics.management.profileUserLinks.insert
# --entity shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
# --permissions shape: {local?: list<string>}
# --userRef shape: {email?: string, id?: string, kind?: string}
export def "management-accounts-webproperties-profiles-entity-user-links create" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/entityUserLinks") $qp)
  let req_body = {"entity": $entity, "id": $id, "kind": $kind, "permissions": $permissions, "selfLink": $self_link, "userRef": $user_ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Removes a user from the given view (profile).
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks/{linkId}
# operationId: analytics.management.profileUserLinks.delete
export def "management-accounts-webproperties-profiles-entity-user-links delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/entityUserLinks/{link_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates permissions for an existing user on the given view (profile).
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/entityUserLinks/{linkId}
# operationId: analytics.management.profileUserLinks.update
# --entity shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
# --permissions shape: {local?: list<string>}
# --userRef shape: {email?: string, id?: string, kind?: string}
export def "management-accounts-webproperties-profiles-entity-user-links update" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --entity: record # Entity for this link. It can be an account, a web property, or a view (profile). — shape: {accountRef?: record, profileRef?: record, webPropertyRef?: record}
  --id: string # Entity user link ID
  --kind: string # Resource type for entity user link. (default: analytics#entityUserLink)
  --permissions: record # Permissions the user has for this entity. — shape: {local?: list<string>}
  --self-link: string # Self link for this resource.
  --user-ref: record # JSON template for a user reference. — shape: {email?: string, id?: string, kind?: string}
]: any -> record<entity: record<accountRef: record<href: string, id: string, kind: string, name: string>, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, webPropertyRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string>>, id: string, kind: string, permissions: record<effective: list<string>, local: list<string>>, selfLink: string, userRef: record<email: string, id: string, kind: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/entityUserLinks/{link_id}") $qp)
  let req_body = {"entity": $entity, "id": $id, "kind": $kind, "permissions": $permissions, "selfLink": $self_link, "userRef": $user_ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists experiments to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments
# operationId: analytics.management.experiments.list
export def "management-accounts-webproperties-profiles-experiments list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of experiments to include in this response.
  --start-index: int # An index of the first experiment to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: list, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/experiments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new experiment.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments
# operationId: analytics.management.experiments.insert
# --parentLink shape: {href?: string, type?: string}
# --variations item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
export def "management-accounts-webproperties-profiles-experiments create" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this experiment belongs. This field is read-only.
  --created: string # Time the experiment was created. This field is read-only. (format: date-time)
  --description: string # Notes about this experiment.
  --editable-in-ga-ui: oneof<nothing, bool> # If true, the end user will be able to edit the experiment via the Google Analytics user interface.
  --end-time: string # The ending time of the experiment (the time the status changed from RUNNING to ENDED). This field is present only if the experiment has ended. This field is read-only. (format: date-time)
  --equal-weighting: oneof<nothing, bool> # Boolean specifying whether to distribute traffic evenly across all variations. If the value is False, content experiments follows the default behavior of adjusting traffic dynamically based on variation performance. Optional -- defaults to False. This field may not be changed for an experiment whose status is ENDED.
  --id: string # Experiment ID. Required for patch and update. Disallowed for create.
  --internal-web-property-id: string # Internal ID for the web property to which this experiment belongs. This field is read-only.
  --kind: string # Resource type for an Analytics experiment. This field is read-only. (default: analytics#experiment)
  --minimum-experiment-length-in-days: int # An integer number in [3, 90]. Specifies the minimum length of the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: int32)
  --name: string # Experiment name. This field may not be changed for an experiment whose status is ENDED. This field is required when creating an experiment.
  --objective-metric: string # The metric that the experiment is optimizing. Valid values: "ga:goal(n)Completions", "ga:adsenseAdsClicks", "ga:adsenseAdsViewed", "ga:adsenseRevenue", "ga:bounces", "ga:pageviews", "ga:sessionDuration", "ga:transactions", "ga:transactionRevenue". This field is required if status is "RUNNING" and servingFramework is one of "REDIRECT" or "API".
  --optimization-type: string # Whether the objectiveMetric should be minimized or maximized. Possible values: "MAXIMUM", "MINIMUM". Optional--defaults to "MAXIMUM". Cannot be specified without objectiveMetric. Cannot be modified when status is "RUNNING" or "ENDED".
  --parent-link: record # Parent link for an experiment. Points to the view (profile) to which this experiment belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this experiment belongs. This field is read-only.
  --reason-experiment-ended: string # Why the experiment ended. Possible values: "STOPPED_BY_USER", "WINNER_FOUND", "EXPERIMENT_EXPIRED", "ENDED_WITH_NO_WINNER", "GOAL_OBJECTIVE_CHANGED". "ENDED_WITH_NO_WINNER" means that the experiment didn't expire but no winner was projected to be found. If the experiment status is changed via the API to ENDED this field is set to STOPPED_BY_USER. This field is read-only.
  --rewrite-variation-urls-as-original: oneof<nothing, bool> # Boolean specifying whether variations URLS are rewritten to match those of the original. This field may not be changed for an experiments whose status is ENDED.
  --self-link: string # Link for this experiment. This field is read-only.
  --serving-framework: string # The framework used to serve the experiment variations and evaluate the results. One of: - REDIRECT: Google Analytics redirects traffic to different variation pages, reports the chosen variation and evaluates the results. - API: Google Analytics chooses and reports the variation to serve and evaluates the results; the caller is responsible for serving the selected variation. - EXTERNAL: The variations will be served externally and the chosen variation reported to Google Analytics. The caller is responsible for serving the selected variation and evaluating the results.
  --snippet: string # The snippet of code to include on the control page(s). This field is read-only.
  --start-time: string # The starting time of the experiment (the time the status changed from READY_TO_RUN to RUNNING). This field is present only if the experiment has started. This field is read-only. (format: date-time)
  --status: string # Experiment status. Possible values: "DRAFT", "READY_TO_RUN", "RUNNING", "ENDED". Experiments can be created in the "DRAFT", "READY_TO_RUN" or "RUNNING" state. This field is required when creating an experiment.
  --traffic-coverage: float # A floating-point number in (0, 1]. Specifies the fraction of the traffic that participates in the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --updated: string # Time the experiment was last modified. This field is read-only. (format: date-time)
  --variations: list # Array of variations. The first variation in the array is the original. The number of variations may not change once an experiment is in the RUNNING state. At least two variations are required before status can be set to RUNNING. — item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
  --body-web-property-id: string # Web property ID to which this experiment belongs. The web property ID is of the form UA-XXXXX-YY. This field is read-only.
  --winner-confidence-level: float # A floating-point number in (0, 1). Specifies the necessary confidence level to choose a winner. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --winner-found: oneof<nothing, bool> # Boolean specifying whether a winner has been found for this experiment. This field is read-only.
]: any -> record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/experiments") $qp)
  let req_body = {"accountId": $body_account_id, "created": $created, "description": $description, "editableInGaUi": $editable_in_ga_ui, "endTime": $end_time, "equalWeighting": $equal_weighting, "id": $id, "internalWebPropertyId": $internal_web_property_id, "kind": $kind, "minimumExperimentLengthInDays": $minimum_experiment_length_in_days, "name": $name, "objectiveMetric": $objective_metric, "optimizationType": $optimization_type, "parentLink": $parent_link, "profileId": $body_profile_id, "reasonExperimentEnded": $reason_experiment_ended, "rewriteVariationUrlsAsOriginal": $rewrite_variation_urls_as_original, "selfLink": $self_link, "servingFramework": $serving_framework, "snippet": $snippet, "startTime": $start_time, "status": $status, "trafficCoverage": $traffic_coverage, "updated": $updated, "variations": $variations, "webPropertyId": $body_web_property_id, "winnerConfidenceLevel": $winner_confidence_level, "winnerFound": $winner_found} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an experiment.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# operationId: analytics.management.experiments.delete
export def "management-accounts-webproperties-profiles-experiments delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), experiment_id: (encode-path-segment $experiment_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/experiments/{experiment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns an experiment to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# operationId: analytics.management.experiments.get
export def "management-accounts-webproperties-profiles-experiments get" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), experiment_id: (encode-path-segment $experiment_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/experiments/{experiment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an existing experiment. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# operationId: analytics.management.experiments.patch
# --parentLink shape: {href?: string, type?: string}
# --variations item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
export def "management-accounts-webproperties-profiles-experiments update-by-accountId-webPropertyId-profileId-experimentId" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this experiment belongs. This field is read-only.
  --created: string # Time the experiment was created. This field is read-only. (format: date-time)
  --description: string # Notes about this experiment.
  --editable-in-ga-ui: oneof<nothing, bool> # If true, the end user will be able to edit the experiment via the Google Analytics user interface.
  --end-time: string # The ending time of the experiment (the time the status changed from RUNNING to ENDED). This field is present only if the experiment has ended. This field is read-only. (format: date-time)
  --equal-weighting: oneof<nothing, bool> # Boolean specifying whether to distribute traffic evenly across all variations. If the value is False, content experiments follows the default behavior of adjusting traffic dynamically based on variation performance. Optional -- defaults to False. This field may not be changed for an experiment whose status is ENDED.
  --id: string # Experiment ID. Required for patch and update. Disallowed for create.
  --internal-web-property-id: string # Internal ID for the web property to which this experiment belongs. This field is read-only.
  --kind: string # Resource type for an Analytics experiment. This field is read-only. (default: analytics#experiment)
  --minimum-experiment-length-in-days: int # An integer number in [3, 90]. Specifies the minimum length of the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: int32)
  --name: string # Experiment name. This field may not be changed for an experiment whose status is ENDED. This field is required when creating an experiment.
  --objective-metric: string # The metric that the experiment is optimizing. Valid values: "ga:goal(n)Completions", "ga:adsenseAdsClicks", "ga:adsenseAdsViewed", "ga:adsenseRevenue", "ga:bounces", "ga:pageviews", "ga:sessionDuration", "ga:transactions", "ga:transactionRevenue". This field is required if status is "RUNNING" and servingFramework is one of "REDIRECT" or "API".
  --optimization-type: string # Whether the objectiveMetric should be minimized or maximized. Possible values: "MAXIMUM", "MINIMUM". Optional--defaults to "MAXIMUM". Cannot be specified without objectiveMetric. Cannot be modified when status is "RUNNING" or "ENDED".
  --parent-link: record # Parent link for an experiment. Points to the view (profile) to which this experiment belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this experiment belongs. This field is read-only.
  --reason-experiment-ended: string # Why the experiment ended. Possible values: "STOPPED_BY_USER", "WINNER_FOUND", "EXPERIMENT_EXPIRED", "ENDED_WITH_NO_WINNER", "GOAL_OBJECTIVE_CHANGED". "ENDED_WITH_NO_WINNER" means that the experiment didn't expire but no winner was projected to be found. If the experiment status is changed via the API to ENDED this field is set to STOPPED_BY_USER. This field is read-only.
  --rewrite-variation-urls-as-original: oneof<nothing, bool> # Boolean specifying whether variations URLS are rewritten to match those of the original. This field may not be changed for an experiments whose status is ENDED.
  --self-link: string # Link for this experiment. This field is read-only.
  --serving-framework: string # The framework used to serve the experiment variations and evaluate the results. One of: - REDIRECT: Google Analytics redirects traffic to different variation pages, reports the chosen variation and evaluates the results. - API: Google Analytics chooses and reports the variation to serve and evaluates the results; the caller is responsible for serving the selected variation. - EXTERNAL: The variations will be served externally and the chosen variation reported to Google Analytics. The caller is responsible for serving the selected variation and evaluating the results.
  --snippet: string # The snippet of code to include on the control page(s). This field is read-only.
  --start-time: string # The starting time of the experiment (the time the status changed from READY_TO_RUN to RUNNING). This field is present only if the experiment has started. This field is read-only. (format: date-time)
  --status: string # Experiment status. Possible values: "DRAFT", "READY_TO_RUN", "RUNNING", "ENDED". Experiments can be created in the "DRAFT", "READY_TO_RUN" or "RUNNING" state. This field is required when creating an experiment.
  --traffic-coverage: float # A floating-point number in (0, 1]. Specifies the fraction of the traffic that participates in the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --updated: string # Time the experiment was last modified. This field is read-only. (format: date-time)
  --variations: list # Array of variations. The first variation in the array is the original. The number of variations may not change once an experiment is in the RUNNING state. At least two variations are required before status can be set to RUNNING. — item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
  --body-web-property-id: string # Web property ID to which this experiment belongs. The web property ID is of the form UA-XXXXX-YY. This field is read-only.
  --winner-confidence-level: float # A floating-point number in (0, 1). Specifies the necessary confidence level to choose a winner. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --winner-found: oneof<nothing, bool> # Boolean specifying whether a winner has been found for this experiment. This field is read-only.
]: any -> record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), experiment_id: (encode-path-segment $experiment_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/experiments/{experiment_id}") $qp)
  let req_body = {"accountId": $body_account_id, "created": $created, "description": $description, "editableInGaUi": $editable_in_ga_ui, "endTime": $end_time, "equalWeighting": $equal_weighting, "id": $id, "internalWebPropertyId": $internal_web_property_id, "kind": $kind, "minimumExperimentLengthInDays": $minimum_experiment_length_in_days, "name": $name, "objectiveMetric": $objective_metric, "optimizationType": $optimization_type, "parentLink": $parent_link, "profileId": $body_profile_id, "reasonExperimentEnded": $reason_experiment_ended, "rewriteVariationUrlsAsOriginal": $rewrite_variation_urls_as_original, "selfLink": $self_link, "servingFramework": $serving_framework, "snippet": $snippet, "startTime": $start_time, "status": $status, "trafficCoverage": $traffic_coverage, "updated": $updated, "variations": $variations, "webPropertyId": $body_web_property_id, "winnerConfidenceLevel": $winner_confidence_level, "winnerFound": $winner_found} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an existing experiment.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/experiments/{experimentId}
# operationId: analytics.management.experiments.update
# --parentLink shape: {href?: string, type?: string}
# --variations item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
export def "management-accounts-webproperties-profiles-experiments update-by-accountId-webPropertyId-profileId-experimentId-1" [
  account_id: string
  web_property_id: string
  profile_id: string
  experiment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this experiment belongs. This field is read-only.
  --created: string # Time the experiment was created. This field is read-only. (format: date-time)
  --description: string # Notes about this experiment.
  --editable-in-ga-ui: oneof<nothing, bool> # If true, the end user will be able to edit the experiment via the Google Analytics user interface.
  --end-time: string # The ending time of the experiment (the time the status changed from RUNNING to ENDED). This field is present only if the experiment has ended. This field is read-only. (format: date-time)
  --equal-weighting: oneof<nothing, bool> # Boolean specifying whether to distribute traffic evenly across all variations. If the value is False, content experiments follows the default behavior of adjusting traffic dynamically based on variation performance. Optional -- defaults to False. This field may not be changed for an experiment whose status is ENDED.
  --id: string # Experiment ID. Required for patch and update. Disallowed for create.
  --internal-web-property-id: string # Internal ID for the web property to which this experiment belongs. This field is read-only.
  --kind: string # Resource type for an Analytics experiment. This field is read-only. (default: analytics#experiment)
  --minimum-experiment-length-in-days: int # An integer number in [3, 90]. Specifies the minimum length of the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: int32)
  --name: string # Experiment name. This field may not be changed for an experiment whose status is ENDED. This field is required when creating an experiment.
  --objective-metric: string # The metric that the experiment is optimizing. Valid values: "ga:goal(n)Completions", "ga:adsenseAdsClicks", "ga:adsenseAdsViewed", "ga:adsenseRevenue", "ga:bounces", "ga:pageviews", "ga:sessionDuration", "ga:transactions", "ga:transactionRevenue". This field is required if status is "RUNNING" and servingFramework is one of "REDIRECT" or "API".
  --optimization-type: string # Whether the objectiveMetric should be minimized or maximized. Possible values: "MAXIMUM", "MINIMUM". Optional--defaults to "MAXIMUM". Cannot be specified without objectiveMetric. Cannot be modified when status is "RUNNING" or "ENDED".
  --parent-link: record # Parent link for an experiment. Points to the view (profile) to which this experiment belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this experiment belongs. This field is read-only.
  --reason-experiment-ended: string # Why the experiment ended. Possible values: "STOPPED_BY_USER", "WINNER_FOUND", "EXPERIMENT_EXPIRED", "ENDED_WITH_NO_WINNER", "GOAL_OBJECTIVE_CHANGED". "ENDED_WITH_NO_WINNER" means that the experiment didn't expire but no winner was projected to be found. If the experiment status is changed via the API to ENDED this field is set to STOPPED_BY_USER. This field is read-only.
  --rewrite-variation-urls-as-original: oneof<nothing, bool> # Boolean specifying whether variations URLS are rewritten to match those of the original. This field may not be changed for an experiments whose status is ENDED.
  --self-link: string # Link for this experiment. This field is read-only.
  --serving-framework: string # The framework used to serve the experiment variations and evaluate the results. One of: - REDIRECT: Google Analytics redirects traffic to different variation pages, reports the chosen variation and evaluates the results. - API: Google Analytics chooses and reports the variation to serve and evaluates the results; the caller is responsible for serving the selected variation. - EXTERNAL: The variations will be served externally and the chosen variation reported to Google Analytics. The caller is responsible for serving the selected variation and evaluating the results.
  --snippet: string # The snippet of code to include on the control page(s). This field is read-only.
  --start-time: string # The starting time of the experiment (the time the status changed from READY_TO_RUN to RUNNING). This field is present only if the experiment has started. This field is read-only. (format: date-time)
  --status: string # Experiment status. Possible values: "DRAFT", "READY_TO_RUN", "RUNNING", "ENDED". Experiments can be created in the "DRAFT", "READY_TO_RUN" or "RUNNING" state. This field is required when creating an experiment.
  --traffic-coverage: float # A floating-point number in (0, 1]. Specifies the fraction of the traffic that participates in the experiment. Can be changed for a running experiment. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --updated: string # Time the experiment was last modified. This field is read-only. (format: date-time)
  --variations: list # Array of variations. The first variation in the array is the original. The number of variations may not change once an experiment is in the RUNNING state. At least two variations are required before status can be set to RUNNING. — item shape: {name?: string, status?: string, url?: string, weight?: float, won?: bool}
  --body-web-property-id: string # Web property ID to which this experiment belongs. The web property ID is of the form UA-XXXXX-YY. This field is read-only.
  --winner-confidence-level: float # A floating-point number in (0, 1). Specifies the necessary confidence level to choose a winner. This field may not be changed for an experiments whose status is ENDED. (format: double)
  --winner-found: oneof<nothing, bool> # Boolean specifying whether a winner has been found for this experiment. This field is read-only.
]: any -> record<accountId: string, created: string, description: string, editableInGaUi: bool, endTime: string, equalWeighting: bool, id: string, internalWebPropertyId: string, kind: string, minimumExperimentLengthInDays: int, name: string, objectiveMetric: string, optimizationType: string, parentLink: record<href: string, type: string>, profileId: string, reasonExperimentEnded: string, rewriteVariationUrlsAsOriginal: bool, selfLink: string, servingFramework: string, snippet: string, startTime: string, status: string, trafficCoverage: float, updated: string, variations: table<name: string, status: string, url: string, weight: float, won: bool>, webPropertyId: string, winnerConfidenceLevel: float, winnerFound: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), experiment_id: (encode-path-segment $experiment_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/experiments/{experiment_id}") $qp)
  let req_body = {"accountId": $body_account_id, "created": $created, "description": $description, "editableInGaUi": $editable_in_ga_ui, "endTime": $end_time, "equalWeighting": $equal_weighting, "id": $id, "internalWebPropertyId": $internal_web_property_id, "kind": $kind, "minimumExperimentLengthInDays": $minimum_experiment_length_in_days, "name": $name, "objectiveMetric": $objective_metric, "optimizationType": $optimization_type, "parentLink": $parent_link, "profileId": $body_profile_id, "reasonExperimentEnded": $reason_experiment_ended, "rewriteVariationUrlsAsOriginal": $rewrite_variation_urls_as_original, "selfLink": $self_link, "servingFramework": $serving_framework, "snippet": $snippet, "startTime": $start_time, "status": $status, "trafficCoverage": $traffic_coverage, "updated": $updated, "variations": $variations, "webPropertyId": $body_web_property_id, "winnerConfidenceLevel": $winner_confidence_level, "winnerFound": $winner_found} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists goals to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals
# operationId: analytics.management.goals.list
export def "management-accounts-webproperties-profiles-goals list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of goals to include in this response.
  --start-index: int # An index of the first goal to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, active: bool, created: string, eventDetails: record, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record, value: float, visitNumPagesDetails: record, visitTimeOnSiteDetails: record, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/goals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new goal.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals
# operationId: analytics.management.goals.insert
# --eventDetails shape: {eventConditions?: list, useEventValue?: bool}
# --parentLink shape: {href?: string, type?: string}
# --urlDestinationDetails shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
# --visitNumPagesDetails shape: {comparisonType?: string, comparisonValue?: string}
# --visitTimeOnSiteDetails shape: {comparisonType?: string, comparisonValue?: string}
export def "management-accounts-webproperties-profiles-goals create" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this goal belongs.
  --active: oneof<nothing, bool> # Determines whether this goal is active.
  --created: string # Time this goal was created. (format: date-time)
  --event-details: record # Details for the goal of the type EVENT. — shape: {eventConditions?: list, useEventValue?: bool}
  --id: string # Goal ID.
  --internal-web-property-id: string # Internal ID for the web property to which this goal belongs.
  --kind: string # Resource type for an Analytics goal. (default: analytics#goal)
  --name: string # Goal name.
  --parent-link: record # Parent link for a goal. Points to the view (profile) to which this goal belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this goal belongs.
  --self-link: string # Link for this goal.
  --type: string # Goal type. Possible values are URL_DESTINATION, VISIT_TIME_ON_SITE, VISIT_NUM_PAGES, AND EVENT.
  --updated: string # Time this goal was last modified. (format: date-time)
  --url-destination-details: record # Details for the goal of the type URL_DESTINATION. — shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
  --value: float # Goal value. (format: float)
  --visit-num-pages-details: record # Details for the goal of the type VISIT_NUM_PAGES. — shape: {comparisonType?: string, comparisonValue?: string}
  --visit-time-on-site-details: record # Details for the goal of the type VISIT_TIME_ON_SITE. — shape: {comparisonType?: string, comparisonValue?: string}
  --body-web-property-id: string # Web property ID to which this goal belongs. The web property ID is of the form UA-XXXXX-YY.
]: any -> record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/goals") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "created": $created, "eventDetails": $event_details, "id": $id, "internalWebPropertyId": $internal_web_property_id, "kind": $kind, "name": $name, "parentLink": $parent_link, "profileId": $body_profile_id, "selfLink": $self_link, "type": $type, "updated": $updated, "urlDestinationDetails": $url_destination_details, "value": $value, "visitNumPagesDetails": $visit_num_pages_details, "visitTimeOnSiteDetails": $visit_time_on_site_details, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a goal to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}
# operationId: analytics.management.goals.get
export def "management-accounts-webproperties-profiles-goals get" [
  account_id: string
  web_property_id: string
  profile_id: string
  goal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), goal_id: (encode-path-segment $goal_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/goals/{goal_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing goal. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}
# operationId: analytics.management.goals.patch
# --eventDetails shape: {eventConditions?: list, useEventValue?: bool}
# --parentLink shape: {href?: string, type?: string}
# --urlDestinationDetails shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
# --visitNumPagesDetails shape: {comparisonType?: string, comparisonValue?: string}
# --visitTimeOnSiteDetails shape: {comparisonType?: string, comparisonValue?: string}
export def "management-accounts-webproperties-profiles-goals update-by-accountId-webPropertyId-profileId-goalId" [
  account_id: string
  web_property_id: string
  profile_id: string
  goal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this goal belongs.
  --active: oneof<nothing, bool> # Determines whether this goal is active.
  --created: string # Time this goal was created. (format: date-time)
  --event-details: record # Details for the goal of the type EVENT. — shape: {eventConditions?: list, useEventValue?: bool}
  --id: string # Goal ID.
  --internal-web-property-id: string # Internal ID for the web property to which this goal belongs.
  --kind: string # Resource type for an Analytics goal. (default: analytics#goal)
  --name: string # Goal name.
  --parent-link: record # Parent link for a goal. Points to the view (profile) to which this goal belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this goal belongs.
  --self-link: string # Link for this goal.
  --type: string # Goal type. Possible values are URL_DESTINATION, VISIT_TIME_ON_SITE, VISIT_NUM_PAGES, AND EVENT.
  --updated: string # Time this goal was last modified. (format: date-time)
  --url-destination-details: record # Details for the goal of the type URL_DESTINATION. — shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
  --value: float # Goal value. (format: float)
  --visit-num-pages-details: record # Details for the goal of the type VISIT_NUM_PAGES. — shape: {comparisonType?: string, comparisonValue?: string}
  --visit-time-on-site-details: record # Details for the goal of the type VISIT_TIME_ON_SITE. — shape: {comparisonType?: string, comparisonValue?: string}
  --body-web-property-id: string # Web property ID to which this goal belongs. The web property ID is of the form UA-XXXXX-YY.
]: any -> record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), goal_id: (encode-path-segment $goal_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/goals/{goal_id}") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "created": $created, "eventDetails": $event_details, "id": $id, "internalWebPropertyId": $internal_web_property_id, "kind": $kind, "name": $name, "parentLink": $parent_link, "profileId": $body_profile_id, "selfLink": $self_link, "type": $type, "updated": $updated, "urlDestinationDetails": $url_destination_details, "value": $value, "visitNumPagesDetails": $visit_num_pages_details, "visitTimeOnSiteDetails": $visit_time_on_site_details, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing goal.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/goals/{goalId}
# operationId: analytics.management.goals.update
# --eventDetails shape: {eventConditions?: list, useEventValue?: bool}
# --parentLink shape: {href?: string, type?: string}
# --urlDestinationDetails shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
# --visitNumPagesDetails shape: {comparisonType?: string, comparisonValue?: string}
# --visitTimeOnSiteDetails shape: {comparisonType?: string, comparisonValue?: string}
export def "management-accounts-webproperties-profiles-goals update-by-accountId-webPropertyId-profileId-goalId-1" [
  account_id: string
  web_property_id: string
  profile_id: string
  goal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this goal belongs.
  --active: oneof<nothing, bool> # Determines whether this goal is active.
  --created: string # Time this goal was created. (format: date-time)
  --event-details: record # Details for the goal of the type EVENT. — shape: {eventConditions?: list, useEventValue?: bool}
  --id: string # Goal ID.
  --internal-web-property-id: string # Internal ID for the web property to which this goal belongs.
  --kind: string # Resource type for an Analytics goal. (default: analytics#goal)
  --name: string # Goal name.
  --parent-link: record # Parent link for a goal. Points to the view (profile) to which this goal belongs. — shape: {href?: string, type?: string}
  --body-profile-id: string # View (Profile) ID to which this goal belongs.
  --self-link: string # Link for this goal.
  --type: string # Goal type. Possible values are URL_DESTINATION, VISIT_TIME_ON_SITE, VISIT_NUM_PAGES, AND EVENT.
  --updated: string # Time this goal was last modified. (format: date-time)
  --url-destination-details: record # Details for the goal of the type URL_DESTINATION. — shape: {caseSensitive?: bool, firstStepRequired?: bool, matchType?: string, steps?: list, url?: string}
  --value: float # Goal value. (format: float)
  --visit-num-pages-details: record # Details for the goal of the type VISIT_NUM_PAGES. — shape: {comparisonType?: string, comparisonValue?: string}
  --visit-time-on-site-details: record # Details for the goal of the type VISIT_TIME_ON_SITE. — shape: {comparisonType?: string, comparisonValue?: string}
  --body-web-property-id: string # Web property ID to which this goal belongs. The web property ID is of the form UA-XXXXX-YY.
]: any -> record<accountId: string, active: bool, created: string, eventDetails: record<eventConditions: list<record>, useEventValue: bool>, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, profileId: string, selfLink: string, type: string, updated: string, urlDestinationDetails: record<caseSensitive: bool, firstStepRequired: bool, matchType: string, steps: list<record>, url: string>, value: float, visitNumPagesDetails: record<comparisonType: string, comparisonValue: string>, visitTimeOnSiteDetails: record<comparisonType: string, comparisonValue: string>, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), goal_id: (encode-path-segment $goal_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/goals/{goal_id}") $qp)
  let req_body = {"accountId": $body_account_id, "active": $active, "created": $created, "eventDetails": $event_details, "id": $id, "internalWebPropertyId": $internal_web_property_id, "kind": $kind, "name": $name, "parentLink": $parent_link, "profileId": $body_profile_id, "selfLink": $self_link, "type": $type, "updated": $updated, "urlDestinationDetails": $url_destination_details, "value": $value, "visitNumPagesDetails": $visit_num_pages_details, "visitTimeOnSiteDetails": $visit_time_on_site_details, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all profile filter links for a profile.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks
# operationId: analytics.management.profileFilterLinks.list
export def "management-accounts-webproperties-profiles-profile-filter-links list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of profile filter links to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<filterRef: record, id: string, kind: string, profileRef: record, rank: int, selfLink: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/profileFilterLinks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new profile filter link.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks
# operationId: analytics.management.profileFilterLinks.insert
# --filterRef shape: {href?: string, id?: string, kind?: string}
# --profileRef shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
export def "management-accounts-webproperties-profiles-profile-filter-links create" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter-ref: record # JSON template for a profile filter link. — shape: {href?: string, id?: string, kind?: string}
  --id: string # Profile filter link ID.
  --profile-ref: record # JSON template for a linked view (profile). — shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
  --rank: int # The rank of this profile filter link relative to the other filters linked to the same profile. For readonly (i.e., list and get) operations, the rank always starts at 1. For write (i.e., create, update, or delete) operations, you may specify a value between 0 and 255 inclusively, [0, 255]. In order to insert a link at the end of the list, either don't specify a rank or set a rank to a number greater than the largest rank in the list. In order to insert a link to the beginning of the list specify a rank that is less than or equal to 1. The new link will move all existing filters with the same or lower rank down the list. After the link is inserted/updated/deleted all profile filter links will be renumbered starting at 1. (format: int32)
]: any -> record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/profileFilterLinks") $qp)
  let req_body = {"filterRef": $filter_ref, "id": $id, "profileRef": $profile_ref, "rank": $rank} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a profile filter link.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# operationId: analytics.management.profileFilterLinks.delete
export def "management-accounts-webproperties-profiles-profile-filter-links delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/profileFilterLinks/{link_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a single profile filter link.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# operationId: analytics.management.profileFilterLinks.get
export def "management-accounts-webproperties-profiles-profile-filter-links get" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/profileFilterLinks/{link_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an existing profile filter link. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# operationId: analytics.management.profileFilterLinks.patch
# --filterRef shape: {href?: string, id?: string, kind?: string}
# --profileRef shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
export def "management-accounts-webproperties-profiles-profile-filter-links update-by-accountId-webPropertyId-profileId-linkId" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter-ref: record # JSON template for a profile filter link. — shape: {href?: string, id?: string, kind?: string}
  --id: string # Profile filter link ID.
  --profile-ref: record # JSON template for a linked view (profile). — shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
  --rank: int # The rank of this profile filter link relative to the other filters linked to the same profile. For readonly (i.e., list and get) operations, the rank always starts at 1. For write (i.e., create, update, or delete) operations, you may specify a value between 0 and 255 inclusively, [0, 255]. In order to insert a link at the end of the list, either don't specify a rank or set a rank to a number greater than the largest rank in the list. In order to insert a link to the beginning of the list specify a rank that is less than or equal to 1. The new link will move all existing filters with the same or lower rank down the list. After the link is inserted/updated/deleted all profile filter links will be renumbered starting at 1. (format: int32)
]: any -> record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/profileFilterLinks/{link_id}") $qp)
  let req_body = {"filterRef": $filter_ref, "id": $id, "profileRef": $profile_ref, "rank": $rank} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an existing profile filter link.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/profileFilterLinks/{linkId}
# operationId: analytics.management.profileFilterLinks.update
# --filterRef shape: {href?: string, id?: string, kind?: string}
# --profileRef shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
export def "management-accounts-webproperties-profiles-profile-filter-links update-by-accountId-webPropertyId-profileId-linkId-1" [
  account_id: string
  web_property_id: string
  profile_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --filter-ref: record # JSON template for a profile filter link. — shape: {href?: string, id?: string, kind?: string}
  --id: string # Profile filter link ID.
  --profile-ref: record # JSON template for a linked view (profile). — shape: {accountId?: string, href?: string, id?: string, internalWebPropertyId?: string, kind?: string, name?: string, webPropertyId?: string}
  --rank: int # The rank of this profile filter link relative to the other filters linked to the same profile. For readonly (i.e., list and get) operations, the rank always starts at 1. For write (i.e., create, update, or delete) operations, you may specify a value between 0 and 255 inclusively, [0, 255]. In order to insert a link at the end of the list, either don't specify a rank or set a rank to a number greater than the largest rank in the list. In order to insert a link to the beginning of the list specify a rank that is less than or equal to 1. The new link will move all existing filters with the same or lower rank down the list. After the link is inserted/updated/deleted all profile filter links will be renumbered starting at 1. (format: int32)
]: any -> record<filterRef: record<accountId: string, href: string, id: string, kind: string, name: string>, id: string, kind: string, profileRef: record<accountId: string, href: string, id: string, internalWebPropertyId: string, kind: string, name: string, webPropertyId: string>, rank: int, selfLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), link_id: (encode-path-segment $link_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/profileFilterLinks/{link_id}") $qp)
  let req_body = {"filterRef": $filter_ref, "id": $id, "profileRef": $profile_ref, "rank": $rank} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists unsampled reports to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports
# operationId: analytics.management.unsampledReports.list
export def "management-accounts-webproperties-profiles-unsampled-reports list" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of unsampled reports to include in this response.
  --start-index: int # An index of the first unsampled report to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<accountId: string, cloudStorageDownloadDetails: record, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record, end_date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start_date: string, status: string, title: string, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/unsampledReports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new unsampled report.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports
# operationId: analytics.management.unsampledReports.insert
# --cloudStorageDownloadDetails shape: {bucketId?: string, objectId?: string}
# --driveDownloadDetails shape: {documentId?: string}
export def "management-accounts-webproperties-profiles-unsampled-reports create" [
  account_id: string
  web_property_id: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this unsampled report belongs.
  --dimensions: string # The dimensions for the unsampled report.
  --end-date: string # The end date for the unsampled report.
  --filters: string # The filters for the unsampled report.
  --id: string # Unsampled report ID.
  --metrics: string # The metrics for the unsampled report.
  --body-profile-id: string # View (Profile) ID to which this unsampled report belongs.
  --segment: string # The segment for the unsampled report.
  --start-date: string # The start date for the unsampled report.
  --title: string # Title of the unsampled report.
  --body-web-property-id: string # Web property ID to which this unsampled report belongs. The web property ID is of the form UA-XXXXX-YY.
]: any -> record<accountId: string, cloudStorageDownloadDetails: record<bucketId: string, objectId: string>, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record<documentId: string>, end_date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start_date: string, status: string, title: string, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/unsampledReports") $qp)
  let req_body = {"accountId": $body_account_id, "dimensions": $dimensions, "end-date": $end_date, "filters": $filters, "id": $id, "metrics": $metrics, "profileId": $body_profile_id, "segment": $segment, "start-date": $start_date, "title": $title, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes an unsampled report.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports/{unsampledReportId}
# operationId: analytics.management.unsampledReports.delete
export def "management-accounts-webproperties-profiles-unsampled-reports delete" [
  account_id: string
  web_property_id: string
  profile_id: string
  unsampled_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), unsampled_report_id: (encode-path-segment $unsampled_report_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/unsampledReports/{unsampled_report_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns a single unsampled report.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/profiles/{profileId}/unsampledReports/{unsampledReportId}
# operationId: analytics.management.unsampledReports.get
export def "management-accounts-webproperties-profiles-unsampled-reports get" [
  account_id: string
  web_property_id: string
  profile_id: string
  unsampled_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, cloudStorageDownloadDetails: record<bucketId: string, objectId: string>, created: string, dimensions: string, downloadType: string, driveDownloadDetails: record<documentId: string>, end_date: string, filters: string, id: string, kind: string, metrics: string, profileId: string, segment: string, selfLink: string, start_date: string, status: string, title: string, updated: string, webPropertyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), profile_id: (encode-path-segment $profile_id), unsampled_report_id: (encode-path-segment $unsampled_report_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/profiles/{profile_id}/unsampledReports/{unsampled_report_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists remarketing audiences to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences
# operationId: analytics.management.remarketingAudience.list
export def "management-accounts-webproperties-remarketing-audiences list" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of remarketing audiences to include in this response.
  --start-index: int # An index of the first entity to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
  --type: string
]: nothing -> record<items: table<accountId: string, audienceDefinition: record, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: list, linkedViews: list, name: string, stateBasedAudienceDefinition: record, updated: string, webPropertyId: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/remarketingAudiences") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a new remarketing audience.
#
# POST /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences
# operationId: analytics.management.remarketingAudience.insert
# --audienceDefinition shape: {includeConditions?: record}
# --linkedAdAccounts item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
# --stateBasedAudienceDefinition shape: {excludeConditions?: record, includeConditions?: record}
export def "management-accounts-webproperties-remarketing-audiences create" [
  account_id: string
  web_property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this remarketing audience belongs.
  --audience-definition: record # The simple audience definition that will cause a user to be added to an audience. — shape: {includeConditions?: record}
  --audience-type: string # The type of audience, either SIMPLE or STATE_BASED.
  --id: string # Remarketing Audience ID.
  --kind: string # Collection type. (default: analytics#remarketingAudience)
  --linked-ad-accounts: list # The linked ad accounts associated with this remarketing audience. A remarketing audience can have only one linkedAdAccount currently. — item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
  --linked-views: list<string> # The views (profiles) that this remarketing audience is linked to.
  --name: string # The name of this remarketing audience.
  --state-based-audience-definition: record # A state based audience definition that will cause a user to be added or removed from an audience. — shape: {excludeConditions?: record, includeConditions?: record}
  --body-web-property-id: string # Web property ID of the form UA-XXXXX-YY to which this remarketing audience belongs.
]: any -> record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/remarketingAudiences") $qp)
  let req_body = {"accountId": $body_account_id, "audienceDefinition": $audience_definition, "audienceType": $audience_type, "id": $id, "kind": $kind, "linkedAdAccounts": $linked_ad_accounts, "linkedViews": $linked_views, "name": $name, "stateBasedAudienceDefinition": $state_based_audience_definition, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a remarketing audience.
#
# DELETE /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# operationId: analytics.management.remarketingAudience.delete
export def "management-accounts-webproperties-remarketing-audiences delete" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), remarketing_audience_id: (encode-path-segment $remarketing_audience_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/remarketingAudiences/{remarketing_audience_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a remarketing audience to which the user has access.
#
# GET /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# operationId: analytics.management.remarketingAudience.get
export def "management-accounts-webproperties-remarketing-audiences get" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), remarketing_audience_id: (encode-path-segment $remarketing_audience_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/remarketingAudiences/{remarketing_audience_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an existing remarketing audience. This method supports patch semantics.
#
# PATCH /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# operationId: analytics.management.remarketingAudience.patch
# --audienceDefinition shape: {includeConditions?: record}
# --linkedAdAccounts item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
# --stateBasedAudienceDefinition shape: {excludeConditions?: record, includeConditions?: record}
export def "management-accounts-webproperties-remarketing-audiences update-by-accountId-webPropertyId-remarketingAudienceId" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this remarketing audience belongs.
  --audience-definition: record # The simple audience definition that will cause a user to be added to an audience. — shape: {includeConditions?: record}
  --audience-type: string # The type of audience, either SIMPLE or STATE_BASED.
  --id: string # Remarketing Audience ID.
  --kind: string # Collection type. (default: analytics#remarketingAudience)
  --linked-ad-accounts: list # The linked ad accounts associated with this remarketing audience. A remarketing audience can have only one linkedAdAccount currently. — item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
  --linked-views: list<string> # The views (profiles) that this remarketing audience is linked to.
  --name: string # The name of this remarketing audience.
  --state-based-audience-definition: record # A state based audience definition that will cause a user to be added or removed from an audience. — shape: {excludeConditions?: record, includeConditions?: record}
  --body-web-property-id: string # Web property ID of the form UA-XXXXX-YY to which this remarketing audience belongs.
]: any -> record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), remarketing_audience_id: (encode-path-segment $remarketing_audience_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/remarketingAudiences/{remarketing_audience_id}") $qp)
  let req_body = {"accountId": $body_account_id, "audienceDefinition": $audience_definition, "audienceType": $audience_type, "id": $id, "kind": $kind, "linkedAdAccounts": $linked_ad_accounts, "linkedViews": $linked_views, "name": $name, "stateBasedAudienceDefinition": $state_based_audience_definition, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates an existing remarketing audience.
#
# PUT /management/accounts/{accountId}/webproperties/{webPropertyId}/remarketingAudiences/{remarketingAudienceId}
# operationId: analytics.management.remarketingAudience.update
# --audienceDefinition shape: {includeConditions?: record}
# --linkedAdAccounts item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
# --stateBasedAudienceDefinition shape: {excludeConditions?: record, includeConditions?: record}
export def "management-accounts-webproperties-remarketing-audiences update-by-accountId-webPropertyId-remarketingAudienceId-1" [
  account_id: string
  web_property_id: string
  remarketing_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --body-account-id: string # Account ID to which this remarketing audience belongs.
  --audience-definition: record # The simple audience definition that will cause a user to be added to an audience. — shape: {includeConditions?: record}
  --audience-type: string # The type of audience, either SIMPLE or STATE_BASED.
  --id: string # Remarketing Audience ID.
  --kind: string # Collection type. (default: analytics#remarketingAudience)
  --linked-ad-accounts: list # The linked ad accounts associated with this remarketing audience. A remarketing audience can have only one linkedAdAccount currently. — item shape: {accountId?: string, id?: string, kind?: string, linkedAccountId?: string, remarketingAudienceId?: string, status?: string, type?: string, webPropertyId?: string}
  --linked-views: list<string> # The views (profiles) that this remarketing audience is linked to.
  --name: string # The name of this remarketing audience.
  --state-based-audience-definition: record # A state based audience definition that will cause a user to be added or removed from an audience. — shape: {excludeConditions?: record, includeConditions?: record}
  --body-web-property-id: string # Web property ID of the form UA-XXXXX-YY to which this remarketing audience belongs.
]: any -> record<accountId: string, audienceDefinition: record<includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, audienceType: string, created: string, description: string, id: string, internalWebPropertyId: string, kind: string, linkedAdAccounts: table<accountId: string, eligibleForSearch: bool, id: string, internalWebPropertyId: string, kind: string, linkedAccountId: string, remarketingAudienceId: string, status: string, type: string, webPropertyId: string>, linkedViews: list<string>, name: string, stateBasedAudienceDefinition: record<excludeConditions: record<exclusionDuration: string, segment: string>, includeConditions: record<daysToLookBack: int, isSmartList: bool, kind: string, membershipDurationDays: int, segment: string>>, updated: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), web_property_id: (encode-path-segment $web_property_id), remarketing_audience_id: (encode-path-segment $remarketing_audience_id)} | format pattern "/management/accounts/{account_id}/webproperties/{web_property_id}/remarketingAudiences/{remarketing_audience_id}") $qp)
  let req_body = {"accountId": $body_account_id, "audienceDefinition": $audience_definition, "audienceType": $audience_type, "id": $id, "kind": $kind, "linkedAdAccounts": $linked_ad_accounts, "linkedViews": $linked_views, "name": $name, "stateBasedAudienceDefinition": $state_based_audience_definition, "webPropertyId": $body_web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Hashes the given Client ID.
#
# POST /management/clientId:hashClientId
# operationId: analytics.management.clientId.hashClientId
export def "management-client-id-hash-client-id create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --client-id: string
  --kind: string # default: analytics#hashClientIdRequest
  --web-property-id: string
]: any -> record<clientId: string, hashedClientId: string, kind: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/management/clientId:hashClientId" $qp)
  let req_body = {"clientId": $client_id, "kind": $kind, "webPropertyId": $web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists segments to which the user has access.
#
# GET /management/segments
# operationId: analytics.management.segments.list
export def "management-segments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --max-results: int # The maximum number of segments to include in this response.
  --start-index: int # An index of the first segment to retrieve. Use this parameter as a pagination mechanism along with the max-results parameter.
]: nothing -> record<items: table<created: string, definition: string, id: string, kind: string, name: string, segmentId: string, selfLink: string, type: string, updated: string>, itemsPerPage: int, kind: string, nextLink: string, previousLink: string, startIndex: int, totalResults: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar") (serialize-qp "max-results" $max_results "scalar") (serialize-qp "start-index" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/management/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists all columns for a report type
#
# GET /metadata/{reportType}/columns
# operationId: analytics.metadata.columns.list
export def "metadata-columns list" [
  report_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<attributeNames: list<string>, etag: string, items: table<attributes: record, id: string, kind: string>, kind: string, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({report_type: (encode-path-segment $report_type)} | format pattern "/metadata/{report_type}/columns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates an account ticket.
#
# POST /provisioning/createAccountTicket
# operationId: analytics.provisioning.createAccountTicket
# --account shape: {childLink?: record, created?: string, id?: string, kind?: string, name?: string, permissions?: record, selfLink?: string, starred?: bool, updated?: string}
# --profile shape: {accountId?: string, botFilteringEnabled?: bool, childLink?: record, currency?: string, defaultPage?: string, eCommerceTracking?: bool, enhancedECommerceTracking?: bool, excludeQueryParameters?: string, id?: string, name?: string, parentLink?: record, permissions?: record, siteSearchCategoryParameters?: string, siteSearchQueryParameters?: string, starred?: bool, stripSiteSearchCategoryParameters?: bool, stripSiteSearchQueryParameters?: bool, timezone?: string, type?: string, websiteUrl?: string}
# --webproperty shape: {accountId?: string, childLink?: record, dataRetentionResetOnNewActivity?: bool, dataRetentionTtl?: string, defaultProfileId?: string, id?: string, industryVertical?: string, name?: string, parentLink?: record, permissions?: record, starred?: bool, websiteUrl?: string}
export def "provisioning-create-account-ticket create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account: record # JSON template for Analytics account entry. — shape: {childLink?: record, created?: string, id?: string, kind?: string, name?: string, permissions?: record, selfLink?: string, starred?: bool, updated?: string}
  --id: string # Account ticket ID used to access the account ticket.
  --kind: string # Resource type for account ticket. (default: analytics#accountTicket)
  --profile: record # JSON template for an Analytics view (profile). — shape: {accountId?: string, botFilteringEnabled?: bool, childLink?: record, currency?: string, defaultPage?: string, eCommerceTracking?: bool, enhancedECommerceTracking?: bool, excludeQueryParameters?: string, id?: string, name?: string, parentLink?: record, permissions?: record, siteSearchCategoryParameters?: string, siteSearchQueryParameters?: string, starred?: bool, stripSiteSearchCategoryParameters?: bool, stripSiteSearchQueryParameters?: bool, timezone?: string, type?: string, websiteUrl?: string}
  --redirect-uri: string # Redirect URI where the user will be sent after accepting Terms of Service. Must be configured in APIs console as a callback URL.
  --webproperty: record # JSON template for an Analytics web property. — shape: {accountId?: string, childLink?: record, dataRetentionResetOnNewActivity?: bool, dataRetentionTtl?: string, defaultProfileId?: string, id?: string, industryVertical?: string, name?: string, parentLink?: record, permissions?: record, starred?: bool, websiteUrl?: string}
]: any -> record<account: record<childLink: record<href: string, type: string>, created: string, id: string, kind: string, name: string, permissions: record<effective: list>, selfLink: string, starred: bool, updated: string>, id: string, kind: string, profile: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, redirectUri: string, webproperty: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/provisioning/createAccountTicket" $qp)
  let req_body = {"account": $account, "id": $id, "kind": $kind, "profile": $profile, "redirectUri": $redirect_uri, "webproperty": $webproperty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provision account.
#
# POST /provisioning/createAccountTree
# operationId: analytics.provisioning.createAccountTree
export def "provisioning-create-account-tree create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --account-name: string
  --kind: string # Resource type for account ticket. (default: analytics#accountTreeRequest)
  --profile-name: string
  --timezone: string
  --webproperty-name: string
  --website-url: string
]: any -> record<account: record<childLink: record<href: string, type: string>, created: string, id: string, kind: string, name: string, permissions: record<effective: list>, selfLink: string, starred: bool, updated: string>, kind: string, profile: record<accountId: string, botFilteringEnabled: bool, childLink: record<href: string, type: string>, created: string, currency: string, defaultPage: string, eCommerceTracking: bool, enhancedECommerceTracking: bool, excludeQueryParameters: string, id: string, internalWebPropertyId: string, kind: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, selfLink: string, siteSearchCategoryParameters: string, siteSearchQueryParameters: string, starred: bool, stripSiteSearchCategoryParameters: bool, stripSiteSearchQueryParameters: bool, timezone: string, type: string, updated: string, webPropertyId: string, websiteUrl: string>, webproperty: record<accountId: string, childLink: record<href: string, type: string>, created: string, dataRetentionResetOnNewActivity: bool, dataRetentionTtl: string, defaultProfileId: string, id: string, industryVertical: string, internalWebPropertyId: string, kind: string, level: string, name: string, parentLink: record<href: string, type: string>, permissions: record<effective: list>, profileCount: int, selfLink: string, starred: bool, updated: string, websiteUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/provisioning/createAccountTree" $qp)
  let req_body = {"accountName": $account_name, "kind": $kind, "profileName": $profile_name, "timezone": $timezone, "webpropertyName": $webproperty_name, "websiteUrl": $website_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Insert or update a user deletion requests.
#
# POST /userDeletion/userDeletionRequests:upsert
# operationId: analytics.userDeletion.userDeletionRequest.upsert
# --id shape: {type?: string, userId?: string}
export def "user-deletion-user-deletion-requests-upsert update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --user-ip: string # Deprecated. Please use quotaUser instead.
  --firebase-project-id: string # Firebase Project Id
  --id: record # User ID. — shape: {type?: string, userId?: string}
  --kind: string # Value is "analytics#userDeletionRequest". (default: analytics#userDeletionRequest)
  --property-id: string # Property ID
  --web-property-id: string # Web property ID of the form UA-XXXXX-YY.
]: any -> record<deletionRequestTime: string, firebaseProjectId: string, id: record<type: string, userId: string>, kind: string, propertyId: string, webPropertyId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "userIp" $user_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/userDeletion/userDeletionRequests:upsert" $qp)
  let req_body = {"firebaseProjectId": $firebase_project_id, "id": $id, "kind": $kind, "propertyId": $property_id, "webPropertyId": $web_property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
