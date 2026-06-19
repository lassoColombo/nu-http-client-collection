# Auto-generated client for Feed API vv1.3.1
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-feed/v1.3.1/openapi.json
# Auth: --token flag or $env.FEED_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/feed/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FEED_API_TOKEN | default "" }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.ebay.com/sell/feed/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customer-service-metric-task list" } } | get name | first)
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

# Use this method to return an array of customer service metric tasks. You can limit the tasks returned by specifying a date range. Note: You can pass in either the look_back_days or date_range, but not both.
#
# GET /customer_service_metric_task
# operationId: getCustomerServiceMetricTasks
export def "customer-service-metric-task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # The task creation date range. The results are filtered to include only tasks with a creation date that is equal to the dates specified or is within the specified range. Do not use with the look_back_days parameter.Format: UTCFor example, tasks within a range: yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ Tasks created on March 8, 20202020-03-08T00:00.00.000Z..2020-03-09T00:00:00.000ZMaximum: 90 days
  --feed-type: string # The feed type associated with the task. The only presently supported value is CUSTOMER_SERVICE_METRICS_REPORT.
  --limit: string # The number of customer service metric tasks to return per page of the result set. Use this parameter in conjunction with the offset parameter to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the call retrieves tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Note:This feature employs a zero-based list, where the first item in the list has an offset of 0.Default: 10 Maximum: 500
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default value: 7Range: 1-90 (inclusive)
  --offset: string # The number of customer service metric tasks to skip in the result set before returning the first task in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "scalar") (serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer_service_metric_task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_range": $date_range, "feed_type": $feed_type, "limit": $limit, "look_back_days": $look_back_days, "offset": $offset} | compact), body: null}
}

# Use this method to create a customer service metrics download task with filter criteria for the customer service metrics report. When using this method, specify the feedType and filterCriteria including both evaluationMarketplaceId and customerServiceMetricType for the report. The method returns the location response header containing the call URI to use with getCustomerServiceMetricTask to retrieve status and details on the task.Only CURRENT Customer Service Metrics reports can be generated with the Sell Feed API. PROJECTED reports are not supported at this time. See the getCustomerServiceMetric (/api-docs/sell/analytics/resources/customer_service_metric/methods/getCustomerServiceMetric) method document in the Analytics API for more information about these two types of reports.Note: Before calling this API, retrieve the summary of the seller's performance and rating for the customer service metric by calling getCustomerServiceMetric (part of the Analytics API (/api-docs/sell/analytics/resources/methods)). You can then populate the create task request fields with the values from the response. This technique eliminates failed tasks that request a report for a customerServiceMetricType and evaluationMarketplaceId that are without evaluation.
#
# POST /customer_service_metric_task
# operationId: createCustomerServiceMetricTask
# --filterCriteria shape: {customerServiceMetricType?: string, evaluationMarketplaceId?: string, listingCategories?: list<string>, shippingRegions?: list<string>}
export def "customer-service-metric-task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Use this header to specify the natural language in which the authenticated user desires the response.
  --feed-type: string # The feedType specified for the task. The report lists the transaction details that contribute to the service metrics evaluation. Supported types include:CUSTOMER_SERVICE_METRICS_REPORT
  --filter-criteria: record # A complex data type that filters data for report creation. See CustomerServiceMetricsFilterCriteria for fields and descriptions. — shape: {customerServiceMetricType?: string, evaluationMarketplaceId?: string, listingCategories?: list<string>, shippingRegions?: list<string>}
  --schema-version: string # The version number of the file format. Valid value: 1.0
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer_service_metric_task")
  let req_body = {"feedType": $feed_type, "filterCriteria": $filter_criteria, "schemaVersion": $schema_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"accept-language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Use this method to retrieve customer service metric task details for the specified task. The input is task_id.
#
# GET /customer_service_metric_task/{task_id}
# operationId: getCustomerServiceMetricTask
export def "customer-service-metric-task get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<customerServiceMetricType: string, evaluationMarketplaceId: string, listingCategories: list<string>, shippingRegions: list<string>>, schemaVersion: string, status: string, taskId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/customer_service_metric_task/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method searches for multiple tasks of a specific feed type, and includes date filters and pagination.
#
# GET /inventory_task
# operationId: getInventoryTasks
export def "inventory-task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type associated with the inventory task. Either feed_type or schedule_id is required. Do not use with the schedule_id parameter. Presently, only one feed type is available:LMS_ACTIVE_INVENTORY_REPORT
  --schedule-id: string # The ID of the schedule for which to retrieve the latest result file. This ID is generated when the schedule was created by the createSchedule method. Schedules apply to downloaded reports (LMS_ACTIVE_INVENTORY_REPORT). Either schedule_id or feed_type is required. Do not use with the feed_type parameter.
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default: 7 Range: 1-90 (inclusive)
  --date-range: string # Specifies the range of task creation dates used to filter the results. The results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Note: Maximum date range window size is 90 days.Valid Format (UTC): yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZFor example: Tasks created on March 31, 2021 2021-03-31T00:00:00.000Z..2021-03-31T00:00:00.000Z
  --limit: string # The maximum number of tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --offset: string # The number of tasks to skip in the result set before returning the first task in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned. Default: 0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "schedule_id" $schedule_id "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inventory_task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"feed_type": $feed_type, "schedule_id": $schedule_id, "look_back_days": $look_back_days, "date_range": $date_range, "limit": $limit, "offset": $offset} | compact), body: null}
}

# This method creates an inventory-related download task for a specified feed type with optional filter criteria. When using this method, specify the feedType. This method returns the location response header containing the getInventoryTask call URI to retrieve the inventory task you just created. The URL includes the eBay-assigned task ID, which you can use to reference the inventory task.To retrieve the status of the task, use the getInventoryTask method to retrieve a single task ID or the getInventoryTasks method to retrieve multiple task IDs. Note: The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.Presently, this method supports Active Inventory Report. The ActiveInventoryReport returns a report that contains price and quantity information for all of the active listings for a specific seller. A seller can use this information to maintain their inventory on eBay.
#
# POST /inventory_task
# operationId: createInventoryTask
# --filterCriteria shape: {listingFormat?: string}
export def "inventory-task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type associated with the inventory task you are about to create. Use a feedType that is available for your API. Presently, only one feed type is available:LMS_ACTIVE_INVENTORY_REPORTSee Report download feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-reports-download-feed-types) for more information.
  --filter-criteria: record # The container for the filter fields. This container is used to set the filter criteria for the order report. A seller can retrieve listings for a specified format. — shape: {listingFormat?: string}
  --schema-version: string # The schemaVersion/version number of the file format (use the schema version of the API to which you are programming):Version Details / Schema Version (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Version)Seller Hub feed schema version (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#schema)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inventory_task")
  let req_body = {"feedType": $feed_type, "filterCriteria": $filter_criteria, "schemaVersion": $schema_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This method retrieves the task details and status of the specified inventory-related task. The input is task_id.
#
# GET /inventory_task/{task_id}
# operationId: getInventoryTask
export def "inventory-task get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<listingFormat: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/inventory_task/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method returns the details and status for an array of order tasks based on a specified feed_type or schedule_id. Specifying both feed_type and schedule_id results in an error. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.If specifying the feed_type, limit which order tasks are returned by specifying filters such as the creation date range or period of time using look_back_days. If specifying a schedule_id, the schedule template (that the schedule_id is based on) determines which order tasks are returned (see schedule_id for additional information). Each schedule_id applies to one feed_type.
#
# GET /order_task
# operationId: getOrderTasks
export def "order-task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # The order tasks creation date range. This range is used to filter the results. The filtered results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Only orders less than 90 days old can be retrieved. Do not use with the look_back_days parameter. Format: UTC For example: Tasks within a range yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ Tasks created on September 8, 2019 2019-09-08T00:00:00.000Z..2019-09-09T00:00:00.000Z
  --feed-type: string # The feed type associated with the task. The only presently supported value is LMS_ORDER_REPORT. Do not use with the schedule_id parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
  --limit: string # The maximum number of order tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves order tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used.Default: 10 Maximum: 500
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default: 7 Range: 1-90 (inclusive)
  --offset: string # The number of order tasks to skip in the result set before returning the first order in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.Default: 0
  --schedule-id: string # The schedule ID associated with the order task. A schedule periodically generates a report for the feed type specified by the schedule template (see scheduleTemplateId in createSchedule). Do not use with the feed_type parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "scalar") (serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "schedule_id" $schedule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order_task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_range": $date_range, "feed_type": $feed_type, "limit": $limit, "look_back_days": $look_back_days, "offset": $offset, "schedule_id": $schedule_id} | compact), body: null}
}

# This method creates an order download task with filter criteria for the order report. When using this method, specify the feedType, schemaVersion, and filterCriteria for the report. The method returns the location response header containing the getOrderTask call URI to retrieve the order task you just created. The URL includes the eBay-assigned task ID, which you can use to reference the order task. To retrieve the status of the task, use the getOrderTask method to retrieve a single task ID or the getOrderTasks method to retrieve multiple order task IDs. Note: The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.The following list contains this method's authorization scope and its corresponding feed type:https://api.ebay.com/oauth/api_scope/sell.fulfillment: LMS_ORDER_REPORT For details about how this method is used, see General feed types (/api-docs/sell/static/feed/general-feed-tasks.html) in the Selling Integration Guide. Note: At this time, the createOrderTask method only supports order creation date filters and not modified order date filters. Do not include the modifiedDateRange filter in your request payload.
#
# POST /order_task
# operationId: createOrderTask
# --filterCriteria shape: {creationDateRange?: record, modifiedDateRange?: record, orderStatus?: string}
export def "order-task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type associated with the task. The only presently supported value is LMS_ORDER_REPORT. See Report download feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-reports-download-feed-types) for more information.
  --filter-criteria: record # The type that defines the fields for the order filters. — shape: {creationDateRange?: record, modifiedDateRange?: record, orderStatus?: string}
  --schema-version: string # The schema version of the LMS OrderReport. For the LMS_ORDER_REPORT feed type, see the OrderReport (/devzone/merchant-data/CallRef/OrderReport.html#OrderReport) reference page to see the present schema version. The schemaVersion value is the version number shown at the top of the OrderReport page. Restriction: This value must be 1113 or higher. The OrderReport schema version is updated about every two weeks. All version numbers are odd numbers (even numbers are skipped). For example, the next release version after '1113' is '1115'.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order_task")
  let req_body = {"feedType": $feed_type, "filterCriteria": $filter_criteria, "schemaVersion": $schema_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This method retrieves the task details and status of the specified task. The input is task_id. For details about how this method is used, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide.
#
# GET /order_task/{task_id}
# operationId: getOrderTask
export def "order-task get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<creationDateRange: record<from: string, to: string>, modifiedDateRange: record<from: string, to: string>, orderStatus: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/order_task/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method retrieves an array containing the details and status of all schedules based on the specified feed_type. Use this method to find a schedule if you do not know the schedule_id.
#
# GET /schedule
# operationId: getSchedules
export def "schedule list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feedType associated with the schedule.
  --limit: string # The maximum number of schedules that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves schedules 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --offset: string # The number of schedules to skip in the result set before returning the first schedule in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.Default: 0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, schedules: table<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"feed_type": $feed_type, "limit": $limit, "offset": $offset} | compact), body: null}
}

# This method creates a schedule, which is a subscription to the specified schedule template. A schedule periodically generates a report for the feedType specified by the template. Specify the same feedType as the feedType of the associated schedule template. When creating the schedule, if available from the template, you can specify a preferred trigger hour, day of the week, or day of the month. These and other fields are conditionally available as specified by the template. Note: Make sure to include all fields required by the schedule template (scheduleTemplateId). Call the getScheduleTemplate method (or the getScheduleTemplates method), to find out which fields are required or optional. If a field is optional and a default value is provided by the template, the default value will be used if omitted from the payload.A successful call returns the location response header containing the getSchedule call URI to retrieve the schedule you just created. The URL includes the eBay-assigned schedule ID, which you can use to reference the schedule task. To retrieve the details of the create schedule task, use the getSchedule method for a single schedule ID or the getSchedules method to retrieve all schedule details for the specified feed_type. The number of schedules for each feedType is limited. Error code 160031 is returned when you have reached this maximum. Note: Except for schedules with a HALF-HOUR frequency, all schedules will ideally run at the start of each hour ('00' minutes). Actual start time may vary time may vary due to load and other factors.
#
# POST /schedule
# operationId: createSchedule
export def "schedule create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The name of the feed type for the created schedule. Match the feed_type from the schedule template associated with this schedule.
  --preferred-trigger-day-of-month: int # The preferred day of the month to trigger the schedule. This field can be used with preferredTriggerHour for monthly schedules. The last day of the month is used for numbers larger than the actual number of days in the month. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Minimum: 1Maximum: 31 (format: int32)
  --preferred-trigger-day-of-week: string # The preferred day of the week to trigger the schedule. This field can be used with preferredTriggerHour for weekly schedules. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. For implementation help, refer to eBay API documentation
  --preferred-trigger-hour: string # The preferred two-digit hour of the day to trigger the schedule. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC hhZFor example, the following represents 11:00 am UTC: 11Z
  --schedule-end-date: string # The timestamp on which the report generation (subscription) ends. After this date, the schedule status becomes INACTIVE. Use this field, if available, to end the schedule in the future. This value must be later than scheduleStartDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents UTC October 10, 2021 at 10:00 AM:2021-10-10T10Z
  --schedule-name: string # The schedule name assigned by the user for the created schedule.
  --schedule-start-date: string # The timestamp to start generating the report. After this timestamp, the schedule status becomes active until either the scheduleEndDate occurs or the scheduleTemplateId becomes inactive. Use this field, if available, to start the schedule in the future but before the scheduleEndDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents a schedule start date of UTC October 01, 2020 at 12:00 PM: 2020-01-01T12Z
  --schedule-template-id: string # The ID of the template associated with the schedule ID. You can get this ID from the documentation or by calling the getScheduleTemplates method. This method requires a schedule template ID that is ACTIVE.
  --schema-version: string # The schema version of the schedule feedType. This field is required if the feedType has a schema version.This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schedule")
  let req_body = {"feedType": $feed_type, "preferredTriggerDayOfMonth": $preferred_trigger_day_of_month, "preferredTriggerDayOfWeek": $preferred_trigger_day_of_week, "preferredTriggerHour": $preferred_trigger_hour, "scheduleEndDate": $schedule_end_date, "scheduleName": $schedule_name, "scheduleStartDate": $schedule_start_date, "scheduleTemplateId": $schedule_template_id, "schemaVersion": $schema_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This method deletes an existing schedule. Specify the schedule to delete using the schedule_id path parameter.
#
# DELETE /schedule/{schedule_id}
# operationId: deleteSchedule
export def "schedule delete" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'schedule_id' must be non-empty" } }
  let full_url = (build-url $base ({schedule_id: (encode-path-segment $schedule_id)} | format pattern "/schedule/{schedule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method retrieves schedule details and status of the specified schedule. Specify the schedule to retrieve using the schedule_id. Use the getSchedules method to find a schedule if you do not know the schedule_id.
#
# GET /schedule/{schedule_id}
# operationId: getSchedule
export def "schedule get" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'schedule_id' must be non-empty" } }
  let full_url = (build-url $base ({schedule_id: (encode-path-segment $schedule_id)} | format pattern "/schedule/{schedule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method updates an existing schedule. Specify the schedule to update using the schedule_id path parameter. If the schedule template has changed after the schedule was created or updated, the input will be validated using the changed template. Note: Make sure to include all fields required by the schedule template (scheduleTemplateId). Call the getScheduleTemplate method (or the getScheduleTemplates method), to find out which fields are required or optional. If you do not know the scheduleTemplateId, call the getSchedule method to find out.
#
# PUT /schedule/{schedule_id}
# operationId: updateSchedule
export def "schedule update" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferred-trigger-day-of-month: int # The preferred day of the month to trigger the schedule. This field can be used with preferredTriggerHour for monthly schedules. The last day of the month is used for numbers larger than the actual number of days in the month. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. Minimum: 1Maximum: 31 (format: int32)
  --preferred-trigger-day-of-week: string # The preferred day of the week to trigger the schedule. This field can be used with preferredTriggerHour for weekly schedules. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. For implementation help, refer to eBay API documentation
  --preferred-trigger-hour: string # The preferred two-digit hour of the day to trigger the schedule. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value. Format: UTC hhZFor example, the following represents 11:00 am UTC: 11ZMinimum: 00ZMaximum: 23Z
  --schedule-end-date: string # The timestamp on which the schedule (report generation) ends. After this date, the schedule status becomes INACTIVE. Use this field, if available, to end the schedule in the future. This value must be later than scheduleStartDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents UTC October 10, 2021 at 10:00 AM: 2021-10-10T10Z
  --schedule-name: string # The schedule name assigned by the user for the created schedule.
  --schedule-start-date: string # The timestamp to start generating the report. After this timestamp, the schedule status becomes active until either the scheduleEndDate occurs or the scheduleTemplateId becomes inactive. Use this field, if available, to start the schedule in the future but before the scheduleEndDate (if supplied). This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.Format: UTC yyyy-MM-ddTHHZFor example, the following represents a schedule start date of UTC October 01, 2020 at 12:00 PM: 2020-01-01T12Z
  --schema-version: string # The schema version of the feedType for the schedule. This field is required if the feedType has a schema version. This field is available as specified by the template (scheduleTemplateId). The template can specify this field as optional or required, and optionally provides a default value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'schedule_id' must be non-empty" } }
  let full_url = (build-url $base ({schedule_id: (encode-path-segment $schedule_id)} | format pattern "/schedule/{schedule_id}"))
  let req_body = {"preferredTriggerDayOfMonth": $preferred_trigger_day_of_month, "preferredTriggerDayOfWeek": $preferred_trigger_day_of_week, "preferredTriggerHour": $preferred_trigger_hour, "scheduleEndDate": $schedule_end_date, "scheduleName": $schedule_name, "scheduleStartDate": $schedule_start_date, "schemaVersion": $schema_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This method downloads the latest result file generated by the schedule. The response of this call is a compressed or uncompressed CSV, XML, or JSON file, with the applicable file extension (for example: csv.gz). Specify the schedule_id path parameter to download its last generated file.
#
# GET /schedule/{schedule_id}/download_result_file
# operationId: getLatestResultFile
export def "schedule-download-result-file get-latest" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schedule_id | is-empty) { error make --unspanned { msg: "path parameter 'schedule_id' must be non-empty" } }
  let full_url = (build-url $base ({schedule_id: (encode-path-segment $schedule_id)} | format pattern "/schedule/{schedule_id}/download_result_file"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method retrieves an array containing the details and status of all schedule templates based on the specified feed_type. Use this method to find a schedule template if you do not know the schedule_template_id.
#
# GET /schedule_template
# operationId: getScheduleTemplates
export def "schedule-template list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type of the schedule templates to retrieve.
  --limit: string # The maximum number of schedule templates that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves schedule templates 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --offset: string # The number of schedule templates to skip in the result set before returning the first template in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.Default: 0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, scheduleTemplates: table<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule_template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"feed_type": $feed_type, "limit": $limit, "offset": $offset} | compact), body: null}
}

# This method retrieves the details of the specified template. Specify the template to retrieve using the schedule_template_id path parameter. Use the getScheduleTemplates method to find a schedule template if you do not know the schedule_template_id.
#
# GET /schedule_template/{schedule_template_id}
# operationId: getScheduleTemplate
export def "schedule-template get" [
  schedule_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: table<defaultValue: string, property: string, usage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schedule_template_id | is-empty) { error make --unspanned { msg: "path parameter 'schedule_template_id' must be non-empty" } }
  let full_url = (build-url $base ({schedule_template_id: (encode-path-segment $schedule_template_id)} | format pattern "/schedule_template/{schedule_template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method returns the details and status for an array of tasks based on a specified feed_type or scheduledId. Specifying both feed_type and scheduledId results in an error. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.If specifying the feed_type, limit which tasks are returned by specifying filters, such as the creation date range or period of time using look_back_days. Also, by specifying the feed_type, both on-demand and scheduled reports are returned.If specifying a scheduledId, the schedule template (that the schedule ID is based on) determines which tasks are returned (see schedule_id for additional information). Each scheduledId applies to one feed_type.
#
# GET /task
# operationId: getTasks
export def "task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # Specifies the range of task creation dates used to filter the results. The results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Only tasks that are less than 90 days can be retrieved. Note: Maximum date range window size is 90 days. Valid Format (UTC):yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ For example: Tasks created on September 8, 2019 2019-09-08T00:00:00.000Z..2019-09-09T00:00:00.000Z
  --feed-type: string # The feed type associated with the tasks to be returned. Only use a feedType that is available for your API: Order Feeds: LMS_ORDER_ACK, LMS_ORDER_REPORTLarge Merchant Services (LMS) Feeds: See Available FeedTypes (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl)Do not use with the schedule_id parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
  --limit: string # The maximum number of tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the offset parameter to control the pagination of the output. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0.For example, if offset is set to 10 and limit is set to 10, the call retrieves tasks 11 thru 20 from the result set.If this parameter is omitted, the default value is used. Default: 10 Maximum: 500
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the date_range parameter. If both date_range and look_back_days are omitted, this parameter's default value is used. Default: 7 Range: 1-90 (inclusive)
  --offset: string # The number of tasks to skip in the result set before returning the first task in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned. Default: 0
  --schedule-id: string # The schedule ID associated with the task. A schedule periodically generates a report for the feed type specified by the schedule template (see scheduleTemplateId in createSchedule). Do not use with the feed_type parameter. Since schedules are based on feed types, you can specify a schedule (schedule_id) that returns the needed feed_type.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "scalar") (serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "schedule_id" $schedule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_range": $date_range, "feed_type": $feed_type, "limit": $limit, "look_back_days": $look_back_days, "offset": $offset, "schedule_id": $schedule_id} | compact), body: null}
}

# This method creates an upload task or a download task without filter criteria. When using this method, specify the feedType and the feed file schemaVersion. The feed type specified sets the task as a download or an upload task. For details about the upload and download flows, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide. Note: The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.The following list contains this method's authorization scopes and their corresponding feed types:https://api.ebay.com/oauth/api_scope/sell.inventory: See LMS FeedTypes (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl)https://api.ebay.com/oauth/api_scope/sell.fulfillment: LMS_ORDER_ACK (specify for upload tasks). Also see LMS FeedTypes (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl)https://api.ebay.com/oauth/api_scope/sell.marketing: None*https://api.ebay.com/oauth/api_scope/commerce.catalog.readonly: None** Reserved for future release
#
# POST /task
# operationId: createTask
export def "task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example:X-EBAY-C-MARKETPLACE-ID:EBAY_USThis identifies the eBay marketplace that applies to this task. See MarketplaceIdEnum (/api-docs/sell/feed/types/bas:MarketplaceIdEnum).
  --feed-type: string # The feed type associated with the task. Only use a feedType that is available for your API. Available feed types:Inventory upload feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#trading-upload-feed-types)Fulfillment upload feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-upload-feed-types)Seller Hub feed types (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#availabl)
  --schema-version: string # The schemaVersion/version number of the file format (use the schema version of the API to which you are programming):Version Details / Schema Version (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Version)Seller Hub feed schema version (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#schema)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/task")
  let req_body = {"feedType": $feed_type, "schemaVersion": $schema_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This method retrieves the details and status of the specified task. The input is task_id. For details of how this method is used, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide.
#
# GET /task/{task_id}
# operationId: getTask
export def "task get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/task/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method downloads the file previously uploaded using uploadFile. Specify the task_id from the uploadFile call. Note: With respect to LMS, this method applies to all feed types except LMS_ORDER_REPORT and LMS_ACTIVE_INVENTORY_REPORT. See LMS API Feeds (/api-docs/sell/static/feed/lms-feeds.html) in the Selling Integration Guide.
#
# GET /task/{task_id}/download_input_file
# operationId: getInputFile
export def "task-download-input-file get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/task/{task_id}/download_input_file"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method retrieves the generated file that is associated with the specified task ID. The response of this call is a compressed or uncompressed CSV, XML, or JSON file, with the applicable file extension (for example: csv.gz). For details about how this method is used, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide. Note: The status of the task to retrieve must be in the COMPLETED or COMPLETED_WITH_ERROR state before this method can retrieve the file. You can use the getTask or getTasks method to retrieve the status of the task.
#
# GET /task/{task_id}/download_result_file
# operationId: getResultFile
export def "task-download-result-file get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/task/{task_id}/download_result_file"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This method associates the specified file with the specified task ID and uploads the input file. After the file has been uploaded, the processing of the file begins. Reports often take time to generate and it's common for this method to return an HTTP status of 202, which indicates the report is being generated. Use the getTask with the task ID or getTasks to determine the status of a report. The status flow is QUEUED > IN_PROCESS > COMPLETED or COMPLETED_WITH_ERROR. When the status is COMPLETED or COMPLETED_WITH_ERROR, this indicates the file has been processed and the order report can be downloaded. If there are errors, they will be indicated in the report file. For details of how this method is used in the upload flow, see Working with Order Feeds (/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html) in the Selling Integration Guide. Note: This method applies to all Seller Hub feed types and LMS feed types except LMS_ORDER_REPORT and LMS_ACTIVE_INVENTORY_REPORT. See LMS feed types (/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl) and Seller Hub feed types (/api-docs/sell/static/feed/fx-feeds-quick-reference.html#availabl). Note: You must use a Content-Type header with its value set to "multipart/form-data". See Samples (/api-docs/sell/feed/resources/task/methods/uploadFile#h2-samples) for information.
#
# POST /task/{task_id}/upload_file
# operationId: uploadFile
export def "task-upload-file upload" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --creation-date: string # The file creation date. Format: UTC yyyy-MM-ddThh:mm:ss.SSSZFor example:Created on September 8, 20192019-09-08T00:00:00.000Z
  --file-name: string # The name of the file including its extension (for example, xml or csv) to be uploaded.
  --modification-date: string # The file modified date. Format: UTC yyyy-MM-ddThh:mm:ss.SSSZFor example:Created on September 9, 20192019-09-09T00:00:00.000Z
  --name: string # A content identifier. The only presently supported name is file.
  --parameters: record # The parameters you want associated with the file.
  --read-date: string # The date you read the file. Format: UTC yyyy-MM-ddThh:mm:ss.SSSZFor example:Created on September 10, 20192019-09-10T00:00:00.000Z
  --size: int # The size of the file. (format: int32)
  --type: string # The file type. The only presently supported type is form-data.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/task/{task_id}/upload_file"))
  let req_body = {"creationDate": $creation_date, "fileName": $file_name, "modificationDate": $modification_date, "name": $name, "parameters": $parameters, "readDate": $read_date, "size": $size, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}
