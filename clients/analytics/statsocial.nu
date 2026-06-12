# Auto-generated client for StatSocial Platform API v1.0.0
# Source: https://api.apis.guru/v2/specs/statsocial.com/1.0.0/openapi.json
# Auth: --token flag or $env.STATSOCIAL_PLATFORM_API_TOKEN

const BASE_URL = "http://api.statsocial.com/api"
const DEFAULT_AUTH = "api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STATSOCIAL_PLATFORM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api_key" => { {headers: {api_key: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://api.statsocial.com/api"] }
def auth-scheme-completer [] { ["api_key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications-status get" } } | get name | first)
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

# Used to understand API usage
#
# GET /applications/status/
export def "applications-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # User application key
]: nothing -> record<data: record<remaining_count: int, reports: record<created: string, name: string, report_type: string, status: string>, total_reports_count: int, total_reports_done: int>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applications/status/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain report output
#
# GET /reports/
export def "reports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-hash: string # Unique report hash
  --baseline: int # Default value will be 'world'
  --report-date: int # report_date represents a Unix timestamp of when the report was generated. Default value will be the latest report generated. You can request the /report/dates/ endpoint in order to obtain available timestamps. Date must be in the future.
  --sample: int # Sample report indicator (default: 1)
]: nothing -> record<data: record<Combined_Age: record<18___24: record, 25___34: record, 35___44: record>, Sex: record<Female: record, Male: record>>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_hash" $report_hash "scalar") (serialize-qp "baseline" $baseline "scalar") (serialize-qp "report_date" $report_date "scalar") (serialize-qp "sample" $sample "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain report output
#
# POST /reports/
export def "reports post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-hash: string # Unique report hash
  --baseline: int # Default value will be 'world'
  --report-date: int # report_date represents a Unix timestamp of when the report was generated. Default value will be the latest report generated. You can request the /report/dates/ endpoint in order to obtain available timestamps. Date must be in the future.
  --sample: int # Sample report indicator (default: 1)
]: nothing -> record<data: record<Combined_Age: record<18___24: record, 25___34: record, 35___44: record>, Sex: record<Female: record, Male: record>>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_hash" $report_hash "scalar") (serialize-qp "baseline" $baseline "scalar") (serialize-qp "report_date" $report_date "scalar") (serialize-qp "sample" $sample "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Step 3 of executing custom report
#
# GET /reports/custom/create/
export def "reports-custom-create get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-hash: string # Upload hash to be used for inserting handles
  --filter: string # Filtering options to be used when creating a filtered report. The options must be in JSON form, example: {'gender':['male'],'ages':['18-24'],'countries':['usa']}
]: nothing -> record<data: record<report_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_hash" $upload_hash "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/custom/create/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Step 3 of executing custom report
#
# POST /reports/custom/create/
export def "reports-custom-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-hash: string # Upload hash to be used for inserting handles
  --filter: string # Filtering options to be used when creating a filtered report. The options must be in JSON form, example: {'gender':['male'],'ages':['18-24'],'countries':['usa']}
]: nothing -> record<data: record<report_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_hash" $upload_hash "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/custom/create/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Step 1 of executing custom report
#
# GET /reports/custom/generate/
export def "reports-custom-generate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-name: string # Name of the report
]: nothing -> record<data: record<upload_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_name" $report_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/custom/generate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Step 1 of executing custom report
#
# POST /reports/custom/generate/
export def "reports-custom-generate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-name: string # Name of the report
]: nothing -> record<data: record<upload_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_name" $report_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/custom/generate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Step 2 of executing custom report
#
# GET /reports/custom/insert/
export def "reports-custom-insert get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-hash: string # Upload hash to be used for inserting handles
  --ids: list # List of twitter ids, separated by commas, to be inserted into report. Ids must be enclosed with brackets ie. [177490485] or [177490485,23423434]
]: nothing -> record<data: record<distinct_relations: int, total_relations: int>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_hash" $upload_hash "scalar") (serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/custom/insert/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Step 2 of executing custom report
#
# POST /reports/custom/insert/
export def "reports-custom-insert post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-hash: string # Upload hash to be used for inserting handles
  --ids: list # List of twitter ids, separated by commas, to be inserted into report. Ids must be enclosed with brackets ie. [177490485] or [177490485,23423434]
]: nothing -> record<data: record<distinct_relations: int, total_relations: int>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_hash" $upload_hash "scalar") (serialize-qp "ids" $ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/custom/insert/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get report dates available for a specific report
#
# GET /reports/dates/
export def "reports-dates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-hash: string # Unique report hash
]: nothing -> record<data: list<int>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_hash" $report_hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/dates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get report dates available for a specific report
#
# POST /reports/dates/
export def "reports-dates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-hash: string # Unique report hash
]: nothing -> record<data: list<int>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_hash" $report_hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/dates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of generated reports
#
# GET /reports/status/
export def "reports-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-hash: string # Unique hash belonging to report
]: nothing -> record<msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_hash" $report_hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/status/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of generated reports
#
# POST /reports/status/
export def "reports-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-hash: string # Unique hash belonging to report
]: nothing -> record<msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_hash" $report_hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/status/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used to create tweet reports
#
# GET /reports/tweet/create/
export def "reports-tweet-create get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-name: string # Name of report
  --start-date: int # A unix timestamp. start_date will be set to the previous midnight.
  --end-date: int # A unix timestamp. end_date will be set to the next midnight.
  --terms: string # If you are tracking a single term, then the keyword itself is suffice otherwise, tracking multiple terms must be in JSON form, example '[{"operator":"","word":"http://google.com"},{"operator":"or","word":"#test"},{"operator":"and","word":"test2"}]' Which results in filtering tweets containing 'http://google.com' OR '#test' AND 'test2'. (NOTE) Make sure to URL encode the terms value for multiple terms.
  --filter: string # Filtering options to be used when creating a filtered report. The options must be in JSON form, example: {'gender':['male'],'ages':['18-24'],'countries':['usa']}
]: nothing -> record<data: record<aggregate_report_hash: string, daily_report_hash: string, monthly_report_hash: string, weekly_report_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_name" $report_name "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "terms" $terms "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/tweet/create/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used to create tweet reports
#
# POST /reports/tweet/create/
export def "reports-tweet-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-name: string # Name of report
  --start-date: int # A unix timestamp. start_date will be set to the previous midnight.
  --end-date: int # A unix timestamp. end_date will be set to the next midnight.
  --terms: string # If you are tracking a single term, then the keyword itself is suffice otherwise, tracking multiple terms must be in JSON form, example '[{"operator":"","word":"http://google.com"},{"operator":"or","word":"#test"},{"operator":"and","word":"test2"}]' Which results in filtering tweets containing 'http://google.com' OR '#test' AND 'test2'. (NOTE) Make sure to URL encode the terms value for multiple terms.
  --filter: string # Filtering options to be used when creating a filtered report. The options must be in JSON form, example: {'gender':['male'],'ages':['18-24'],'countries':['usa']}
]: nothing -> record<data: record<aggregate_report_hash: string, daily_report_hash: string, monthly_report_hash: string, weekly_report_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "report_name" $report_name "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "terms" $terms "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/tweet/create/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used to create twitter follower report
#
# GET /reports/twitter/create/
export def "reports-twitter-create get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --twitter-id: int # (required if twitter_handle is not supplied) twitter_id must be sent with all client requests. Multiple handles are separated by commas.
  --twitter-handle: string # (required if twitter_id is not supplied) twitter_handle must be sent with all client requests. Multiple ids are separated by commas.
  --filter: string # Filtering options to be used when creating a filtered report. The options must be in JSON form, example: {'gender':['male'],'ages':['18-24'],'countries':['usa']}
]: nothing -> record<data: record<report_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "twitter_id" $twitter_id "scalar") (serialize-qp "twitter_handle" $twitter_handle "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/twitter/create/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Used to create twitter follower report
#
# POST /reports/twitter/create/
export def "reports-twitter-create post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --twitter-id: int # (required if twitter_handle is not supplied) twitter_id must be sent with all client requests. Multiple handles are separated by commas.
  --twitter-handle: string # (required if twitter_id is not supplied) twitter_handle must be sent with all client requests. Multiple ids are separated by commas.
  --filter: string # Filtering options to be used when creating a filtered report. The options must be in JSON form, example: {'gender':['male'],'ages':['18-24'],'countries':['usa']}
]: nothing -> record<data: record<report_hash: string>, msg: string, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "twitter_id" $twitter_id "scalar") (serialize-qp "twitter_handle" $twitter_handle "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/twitter/create/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
