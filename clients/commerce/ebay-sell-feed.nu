# Auto-generated client for Feed API vv1.3.1
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-feed/v1.3.1/openapi.json
# Auth: --token flag or $env.FEED_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/feed/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FEED_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ebay.com/sell/feed/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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

# Use this method to return an array of customer service metric tasks. You can limit the tasks returned by specifying a date range. </p> <p> <span class="tablenote"><strong>Note:</strong> You can pass in either the <code>look_back_days </code>or<code> date_range</code>, but not both.</span></p>
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # The task creation date range. The results are filtered to include only tasks with a creation date that is equal to the dates specified or is within the specified range. Do not use with the <code>look_back_days</code> parameter.<p><strong>Format: </strong>UTC</p><p>For example, tasks within a range: </p><p><code>yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ </code></p><p>Tasks created on March 8, 2020</p><p><code>2020-03-08T00:00.00.000Z..2020-03-09T00:00:00.000Z</code></p><p><b>Maximum: </b>90 days</p>
  --feed-type: string # The feed type associated with the task. The only presently supported value is <code>CUSTOMER_SERVICE_METRICS_REPORT</code>.
  --limit: string # The number of customer service metric tasks to return per page of the result set. Use this parameter in conjunction with the offset parameter to control the pagination of the output. <p>For example, if <strong>offset</strong> is set to 10 and <strong>limit</strong> is set to 10, the call retrieves tasks 11 thru 20 from the result set.</p><p>If this parameter is omitted, the default value is used.</p><p> <span class="tablenote"><strong>Note:</strong>This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span></p><p><b>Default:</b> 10 <p><b>Maximum:</b> 500</p>
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the <code>date_range</code> parameter. If both <code>date_range</code> and <code>look_back_days</code> are omitted, this parameter's default value is used. <p><b>Default value:</b> 7</p><p><b>Range:</b> 1-90 (inclusive)</p>
  --offset: string # The number of customer service metric tasks to skip in the result set before returning the first task in the paginated response. <p>Combine <strong>offset</strong> with the <strong>limit</strong> query parameter to control the items returned in the response. For example, if you supply an <strong>offset</strong> of <code>0</code> and a <strong>limit</strong> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <strong>offset</strong> is <code>10</code> and <strong>limit</strong> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set. <br /><br /><b>Default: </b>0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "scalar") (serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer_service_metric_task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <p>Use this method to create a customer service metrics download task with filter criteria for the customer service metrics report. When using this method, specify the <strong>feedType</strong> and <strong>filterCriteria</strong> including both <strong>evaluationMarketplaceId</strong> and <strong>customerServiceMetricType</strong> for the report. The method returns the location response header containing the call URI to use with <strong>getCustomerServiceMetricTask</strong> to retrieve status and details on the task.</p><p>Only CURRENT Customer Service Metrics reports can be generated with the Sell Feed API. PROJECTED reports are not supported at this time. See the <a href="/api-docs/sell/analytics/resources/customer_service_metric/methods/getCustomerServiceMetric">getCustomerServiceMetric</a> method document in the Analytics API for more information about these two types of reports.</p><p><span class="tablenote"><strong>Note:</strong> Before calling this API, retrieve the summary of the seller's performance and rating for the customer service metric by calling <strong>getCustomerServiceMetric</strong> (part of the <a href="/api-docs/sell/analytics/resources/methods">Analytics API</a>). You can then populate the create task request fields with the values from the response. This technique eliminates failed tasks that request a report for a <strong>customerServiceMetricType</strong> and <strong>evaluationMarketplaceId</strong> that are without evaluation.</span></p>
#
# POST /customer_service_metric_task
# operationId: createCustomerServiceMetricTask
# --filterCriteria shape: {customerServiceMetricType?: string, evaluationMarketplaceId?: string, listingCategories?: list, shippingRegions?: list}
export def "customer-service-metric-task createCustomerServiceMetricTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Use this header to specify the natural language in which the authenticated user desires the response.
  --feedType: string # The <strong>feedType</strong> specified for the task. The report lists the transaction details that contribute to the service metrics evaluation. Supported types include:<p><code>CUSTOMER_SERVICE_METRICS_REPORT</code></p>
  --filterCriteria: record # A complex data type that filters data for report creation. See <strong>CustomerServiceMetricsFilterCriteria</strong> for fields and descriptions. — shape: {customerServiceMetricType?: string, evaluationMarketplaceId?: string, listingCategories?: list, shippingRegions?: list}
  --schemaVersion: string # The version number of the file format. <p><b>Valid value: </b><code>1.0</code><p>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer_service_metric_task")
  let body = {feedType: $feedType, filterCriteria: $filterCriteria, schemaVersion: $schemaVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"accept-language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Use this method to retrieve customer service metric task details for the specified task. The input is <strong>task_id</strong>.</p>
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<customerServiceMetricType: string, evaluationMarketplaceId: string, listingCategories: list<string>, shippingRegions: list<string>>, schemaVersion: string, status: string, taskId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer_service_metric_task/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type associated with the inventory task. Either <strong>feed_type</strong> or <strong>schedule_id</strong> is required. Do not use with the <strong>schedule_id</strong> parameter. Presently, only one feed type is available:<ul><li><code>LMS_ACTIVE_INVENTORY_REPORT</code></li></ul>
  --schedule-id: string # The ID of the schedule for which to retrieve the latest result file. This ID is generated when the schedule was created by the <strong>createSchedule</strong> method. Schedules apply to downloaded reports (<code>LMS_ACTIVE_INVENTORY_REPORT</code>). Either <strong>schedule_id</strong> or <strong>feed_type</strong> is  required. Do not use with the <strong>feed_type</strong> parameter.
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the <code>date_range</code> parameter. If both <code>date_range</code> and <code>look_back_days</code> are omitted, this parameter's default value is used.  <br /><br /><b>Default: </b> 7 <br /><br /><b>Range: </b> 1-90 (inclusive)
  --date-range: string # Specifies the range of task creation dates used to filter the results. The results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. <p> <span class="tablenote"><strong>Note:</strong> Maximum date range window size is 90 days.</span></p><br /><b>Valid Format (UTC): </b><code>yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ</code><br /><br />For example: Tasks created on March 31, 2021<br /> <code>2021-03-31T00:00:00.000Z..2021-03-31T00:00:00.000Z</code><br /><br />
  --limit: string # The maximum number of tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the <strong>offset</strong> parameter to control the pagination of the output. <p> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span></p><p>For example, if <strong>offset</strong> is set to 10 and <strong>limit</strong> is set to 10, the call retrieves tasks 11 thru 20 from the result set.</p><p>If this parameter is omitted, the default value is used. <br /><br /><b>Default: </b> 10 <br /><br /><b>Maximum: </b>500
  --offset: string # The number of tasks to skip in the result set before returning the first task in the paginated response. <p>Combine <strong>offset</strong> with the <strong>limit</strong> query parameter to control the items returned in the response. For example, if you supply an <strong>offset</strong> of <code>0</code> and a <strong>limit</strong> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <strong>offset</strong> is <code>10</code> and <strong>limit</strong> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned. <br /><br /><b>Default: </b>0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "schedule_id" $schedule_id "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "date_range" $date_range "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inventory_task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates an inventory-related download task for a specified feed type with optional filter criteria. When using this method, specify the <strong>feedType</strong>. <br/><br/>This method returns the location response header containing the <strong>getInventoryTask</strong> call URI to retrieve the inventory task you just created. The URL includes the eBay-assigned task ID, which you can use to reference the inventory task.<br/><br/>To retrieve the status of the task, use the <strong>getInventoryTask</strong> method to retrieve a single task ID or the <strong>getInventoryTasks</strong> method to retrieve multiple task IDs.<p> <span class="tablenote"><strong>Note:</strong> The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.</span></p>Presently, this method supports Active Inventory Report. The <strong>ActiveInventoryReport</strong> returns a report that contains price and quantity information for all of the active listings for a specific seller. A seller can use this information to maintain their inventory on eBay.
#
# POST /inventory_task
# operationId: createInventoryTask
# --filterCriteria shape: {listingFormat?: string}
export def "inventory-task createInventoryTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feedType: string # The feed type associated with the inventory task you are about to create. Use a <strong>feedType</strong> that is available for your API. Presently, only one feed type is available:<ul><li><code>LMS_ACTIVE_INVENTORY_REPORT</code></li></ul><br/>See <a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-reports-download-feed-types" target="_blank">Report download feed types</a> for more information.
  --filterCriteria: record # The container for the filter fields. This container is used to set the filter criteria for the order report. A seller can retrieve listings for a specified format. — shape: {listingFormat?: string}
  --schemaVersion: string # The schemaVersion/version number of the file format (use the schema version of the API to which you are programming):<ul><li><a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Version" target="_blank">Version Details / Schema Version</a></li><li><a href="/api-docs/sell/static/feed/fx-feeds-quick-reference.html#schema" target="_blank">Seller Hub feed schema version</a></li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inventory_task")
  let body = {feedType: $feedType, filterCriteria: $filterCriteria, schemaVersion: $schemaVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves the task details and status of the specified inventory-related task. The input is <strong>task_id</strong>.
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<listingFormat: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inventory_task/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method returns the details and status for an array of order tasks based on a specified <strong>feed_type</strong> or <strong>schedule_id</strong>. Specifying both <strong>feed_type</strong> and <strong>schedule_id</strong> results in an error. Since schedules are based on feed types, you can specify a schedule (<strong>schedule_id</strong>) that returns the needed <strong>feed_type</strong>.<br /><br />If specifying the <strong>feed_type</strong>, limit which order tasks are returned by specifying filters such as the creation date range or period of time using <strong>look_back_days</strong>. <br /><br />If specifying a <strong>schedule_id</strong>, the schedule template (that the <strong>schedule_id</strong> is based on) determines which order tasks are returned (see <strong>schedule_id</strong> for additional information). Each <strong>schedule_id</strong> applies to one <strong>feed_type</strong>.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # The order tasks creation date range. This range is used to filter the results. The filtered results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Only orders less than 90 days old can be retrieved. Do not use with the <strong>look_back_days</strong> parameter. <br /><br /><b>Format: </b>UTC   <br /><br /> <b> For example: </b> <br /><br />Tasks within a range  <br /> <code>yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ </code> <br /><br /> Tasks created on September 8, 2019<br /> <code>2019-09-08T00:00:00.000Z..2019-09-09T00:00:00.000Z</code><br />
  --feed-type: string # The feed type associated with the task. The only presently supported value is <code>LMS_ORDER_REPORT</code>. Do not use with the <strong>schedule_id</strong> parameter. Since schedules are based on feed types, you can specify a schedule (<strong>schedule_id</strong>) that returns the needed <strong>feed_type</strong>.
  --limit: string # The maximum number of order tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the <strong>offset</strong> parameter to control the pagination of the output. <p> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span></p><p>For example, if <strong>offset</strong> is set to 10 and <strong>limit</strong> is set to 10, the call retrieves order tasks 11 thru 20 from the result set.</p><p>If this parameter is omitted, the default value is used.</p><p><b>Default:</b> 10 <p><b>Maximum:</b> 500</p>
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the <strong>date_range</strong> parameter. If both <strong>date_range</strong> and <strong>look_back_days</strong> are omitted, this parameter's default value is used.  <br /><br /><b>Default: </b> 7 <br /><br /><b>Range: </b> 1-90 (inclusive)  
  --offset: string # The number of order tasks to skip in the result set before returning the first order in the paginated response. <p>Combine <strong>offset</strong> with the <strong>limit</strong> query parameter to control the items returned in the response. For example, if you supply an <strong>offset</strong> of <code>0</code> and a <strong>limit</strong> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <strong>offset</strong> is <code>10</code> and <strong>limit</strong> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.<br /><br /><b>Default: </b>0
  --schedule-id: string # The schedule ID associated with the order task. A schedule periodically generates a report for the feed type specified by the schedule template (see <strong>scheduleTemplateId</strong> in <strong>createSchedule</strong>). Do not use with the <strong>feed_type</strong> parameter. Since schedules are based on feed types, you can specify a schedule (<strong>schedule_id</strong>) that returns the needed <strong>feed_type</strong>.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "scalar") (serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "schedule_id" $schedule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order_task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates an order download task with filter criteria for the order report. When using this method, specify the <b> feedType</b>, <b> schemaVersion</b>, and <b> filterCriteria</b> for the report. The method returns the <b> location</b> response header containing the getOrderTask call URI to retrieve the order task you just created. The URL includes the eBay-assigned task ID, which you can use to reference the order task. <br /><br />To retrieve the status of the task, use the <b> getOrderTask</b> method to retrieve a single task ID or the <b>getOrderTasks</b> method to retrieve multiple order task IDs.<p> <span class="tablenote"><strong>Note:</strong> The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.</span></p><p>The following list contains this method's authorization scope and its corresponding feed type:<ul><li>https://api.ebay.com/oauth/api_scope/sell.fulfillment: LMS_ORDER_REPORT</li></ul> </p><p>For details about how this method is used, see <a href="/api-docs/sell/static/feed/general-feed-tasks.html">General feed types</a> in the Selling Integration Guide. <p> <span class="tablenote"><strong>Note:</strong> At this time, the <strong>createOrderTask</strong> method only supports order creation date filters and not modified order date filters. Do not include the <strong>modifiedDateRange</strong> filter in your request payload.</span></p>
#
# POST /order_task
# operationId: createOrderTask
# --filterCriteria shape: {creationDateRange?: record, modifiedDateRange?: record, orderStatus?: string}
export def "order-task createOrderTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feedType: string # The feed type associated with the task. The only presently supported value is <code>LMS_ORDER_REPORT</code>. See <a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-reports-download-feed-types" target="_blank">Report download feed types</a> for more information.
  --filterCriteria: record # The type that defines the fields for the order filters. — shape: {creationDateRange?: record, modifiedDateRange?: record, orderStatus?: string}
  --schemaVersion: string # The schema version of the LMS OrderReport. For the <code>LMS_ORDER_REPORT</code> feed type, see the <a href="/devzone/merchant-data/CallRef/OrderReport.html#OrderReport">OrderReport</a> reference page to see the present schema version. The <b> schemaVersion</b> value is the version number shown at the top of the <b> OrderReport</b> page. <br /><br /><b>Restriction: </b> This value must be 1113 or higher. The OrderReport schema version is updated about every two weeks. All version numbers are odd numbers (even numbers are skipped). For example, the next release version after '1113' is '1115'.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order_task")
  let body = {feedType: $feedType, filterCriteria: $filterCriteria, schemaVersion: $schemaVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves the task details and status of the specified task. The input is <strong>task_id</strong>. <p>For details about how this method is used, see <a href="/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html">Working with Order Feeds</a> in the Selling Integration Guide.  </p>
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, filterCriteria: record<creationDateRange: record<from: string, to: string>, modifiedDateRange: record<from: string, to: string>, orderStatus: string>, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order_task/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves an array containing the details and status of all schedules based on the specified <strong>feed_type</strong>. Use this method to find a schedule if you do not know the <strong>schedule_id</strong>.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The <strong>feedType</strong> associated with the schedule.
  --limit: string # The maximum number of schedules that can be returned on each page of the paginated response. Use this parameter in conjunction with the <strong>offset</strong> parameter to control the pagination of the output. <p> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span></p><p>For example, if <strong>offset</strong> is set to 10 and <strong>limit</strong> is set to 10, the call retrieves schedules 11 thru 20 from the result set.</p><p>If this parameter is omitted, the default value is used. <br /><br /><b>Default: </b> 10 <br /><br /><b>Maximum: </b>500
  --offset: string # The number of schedules to skip in the result set before returning the first schedule in the paginated response. <p>Combine <strong>offset</strong> with the <strong>limit</strong> query parameter to control the items returned in the response. For example, if you supply an <strong>offset</strong> of <code>0</code> and a <strong>limit</strong> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <strong>offset</strong> is <code>10</code> and <strong>limit</strong> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.<br /><br /><b>Default: </b>0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, schedules: table<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates a schedule, which is a subscription to the specified schedule template. A schedule periodically generates a report for the <strong>feedType</strong> specified by the template. Specify the same <strong>feedType</strong> as the <strong>feedType</strong> of the associated schedule template. When creating the schedule, if available from the template, you can specify a preferred trigger hour, day of the week, or day of the month. These and other fields are conditionally available as specified by the template.<p> <span class="tablenote"><strong>Note:</strong> Make sure to include all fields required by the schedule template (<strong>scheduleTemplateId</strong>). Call the <strong>getScheduleTemplate</strong> method (or the <strong>getScheduleTemplates</strong> method), to find out which fields are required or optional. If a field is optional and a default value is provided by the template, the default value will be used if omitted from the payload.</span></p>A successful call returns the location response header containing the <strong>getSchedule</strong> call URI to retrieve the schedule you just created. The URL includes the eBay-assigned schedule ID, which you can use to reference the schedule task. <br /><br />To retrieve the details of the create schedule task, use the <strong>getSchedule</strong> method for a single schedule ID or the <strong>getSchedules</strong> method to retrieve all schedule details for the specified <strong>feed_type</strong>. The number of schedules for each feedType is limited. Error code 160031 is returned when you have reached this maximum.<p> <span class="tablenote"><strong>Note:</strong> Except for schedules with a HALF-HOUR frequency, all schedules will ideally run at the start of each hour ('00' minutes). Actual start time may vary time may vary due to load and other factors.</span></p>
#
# POST /schedule
# operationId: createSchedule
export def "schedule createSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feedType: string # The name of the feed type for the created schedule. Match the <strong>feed_type</strong> from the schedule template associated with this schedule.
  --preferredTriggerDayOfMonth: int # The preferred day of the month to trigger the schedule. This field can be used with <strong>preferredTriggerHour</strong> for monthly schedules. The last day of the month is used for numbers larger than the actual number of days in the month. <br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value.<br /><br /><b>Minimum: </b>1<br /><br /><b>Maximum: </b>31 (format: int32)
  --preferredTriggerDayOfWeek: string # The preferred day of the week to trigger the schedule. This field can be used with <strong>preferredTriggerHour</strong> for weekly schedules. <br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/feed/types/api:DayOfWeekEnum'>eBay API documentation</a>
  --preferredTriggerHour: string # The preferred two-digit hour of the day to trigger the schedule. <br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value.<br /><br /><b>Format:</b> UTC <code>hhZ</code><br /><br />For example, the following represents 11:00 am UTC:<code> 11Z</code>
  --scheduleEndDate: string # The timestamp on which the report generation (subscription) ends. After this date, the schedule status becomes <code>INACTIVE</code>. <br /><br />Use this field, if available, to end the schedule in the future. This value must be later than <strong>scheduleStartDate</strong> (if supplied). This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value.<br /><br /><b>Format:</b> UTC <code>yyyy-MM-dd<strong>T</strong>HH<strong>Z</strong></code><br /><br />For example, the following represents UTC October 10, 2021 at 10:00 AM:<br /><code>2021-10-10T10Z</code>
  --scheduleName: string # The schedule name assigned by the user for the created schedule.
  --scheduleStartDate: string # The timestamp to start generating the report. After this timestamp, the schedule status becomes active until either the <strong>scheduleEndDate</strong> occurs or the <strong>scheduleTemplateId</strong> becomes inactive. <br /><br />Use this field, if available, to start the schedule in the future but before the <strong>scheduleEndDate</strong> (if supplied). This field is available as specified by the template <strong>(scheduleTemplateId)</strong>.  The template can specify this field as optional or required, and optionally provides a default value.<br /><br /><b>Format:</b> UTC <code>yyyy-MM-dd<strong>T</strong>HH<strong>Z</strong></code><br /><br />For example, the following represents a schedule start date of UTC October 01, 2020 at 12:00 PM:<br /><code> 2020-01-01T12Z</code>
  --scheduleTemplateId: string # The ID of the template associated with the schedule ID. You can get this ID from the documentation or by calling the <strong>getScheduleTemplates</strong> method. This method requires a schedule template ID that is <code>ACTIVE</code>.
  --schemaVersion: string # The schema version of the schedule feedType. This field is required if the <strong>feedType</strong> has a schema version.<br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schedule")
  let body = {feedType: $feedType, preferredTriggerDayOfMonth: $preferredTriggerDayOfMonth, preferredTriggerDayOfWeek: $preferredTriggerDayOfWeek, preferredTriggerHour: $preferredTriggerHour, scheduleEndDate: $scheduleEndDate, scheduleName: $scheduleName, scheduleStartDate: $scheduleStartDate, scheduleTemplateId: $scheduleTemplateId, schemaVersion: $schemaVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method deletes an existing schedule. Specify the schedule to delete using the <strong>schedule_id</strong> path parameter.
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedule/($schedule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves schedule details and status of the specified schedule. Specify the schedule to retrieve using the <strong>schedule_id</strong>. Use the <strong>getSchedules</strong> method to find a schedule if you do not know the <strong>schedule_id</strong>.
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<creationDate: string, feedType: string, lastModifiedDate: string, preferredTriggerDayOfMonth: int, preferredTriggerDayOfWeek: string, preferredTriggerHour: string, scheduleEndDate: string, scheduleId: string, scheduleName: string, scheduleStartDate: string, scheduleTemplateId: string, schemaVersion: string, status: string, statusReason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedule/($schedule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method updates an existing schedule. Specify the schedule to update using the <strong>schedule_id</strong> path parameter. If the schedule template has changed after the schedule was created or updated, the input will be validated using the changed template.<p> <span class="tablenote"><strong>Note:</strong> Make sure to include all fields required by the schedule template (<strong>scheduleTemplateId</strong>). Call the <strong>getScheduleTemplate</strong> method (or the <strong>getScheduleTemplates</strong> method), to find out which fields are required or optional. If you do not know the <strong>scheduleTemplateId</strong>, call the <strong>getSchedule</strong> method to find out.</span></p>
#
# PUT /schedule/{schedule_id}
# operationId: updateSchedule
export def "schedule updateSchedule" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferredTriggerDayOfMonth: int # The preferred day of the month to trigger the schedule. This field can be used with <strong>preferredTriggerHour</strong> for monthly schedules. The last day of the month is used for numbers larger than the actual number of days in the month. <br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value. <br /><br /><b>Minimum: </b>1<b><br /><br /><b>Maximum: </b>31 (format: int32)
  --preferredTriggerDayOfWeek: string # The preferred day of the week to trigger the schedule. This field can be used with <strong>preferredTriggerHour</strong> for weekly schedules. <br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/feed/types/api:DayOfWeekEnum'>eBay API documentation</a>
  --preferredTriggerHour: string # The preferred two-digit hour of the day to trigger the schedule. <br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value. <br /><br /><b>Format:</b> UTC <code>hhZ</code><br /><br />For example, the following represents 11:00 am UTC:<code> 11Z</code><br /><br /><b>Minimum: </b><code>00Z</code><b><br /><br /><b>Maximum: </b><code>23Z</code>
  --scheduleEndDate: string # The timestamp on which the schedule (report generation) ends. After this date, the schedule status becomes <code>INACTIVE</code>. <br /><br />Use this field, if available, to end the schedule in the future. This value must be later than <strong>scheduleStartDate</strong> (if supplied). This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value.<br /><br /><b>Format:</b> UTC <code>yyyy-MM-dd<strong>T</strong>HH<strong>Z</strong></code><br /><br />For example, the following represents UTC October 10, 2021 at 10:00 AM:<br /><code> 2021-10-10T10Z</code>
  --scheduleName: string # The schedule name assigned by the user for the created schedule.
  --scheduleStartDate: string # The timestamp to start generating the report. After this timestamp, the schedule status becomes active until either the <strong>scheduleEndDate</strong> occurs or the <strong>scheduleTemplateId</strong> becomes inactive. <br /><br />Use this field, if available, to start the schedule in the future but before the <strong>scheduleEndDate</strong> (if supplied). This field is available as specified by the template <strong>(scheduleTemplateId)</strong>.  The template can specify this field as optional or required, and optionally provides a default value.<br /><br /><b>Format:</b> UTC <code>yyyy-MM-dd<strong>T</strong>HH<strong>Z</strong></code><br /><br />For example, the following represents a schedule start date of UTC October 01, 2020 at 12:00 PM:<br /><code> 2020-01-01T12Z</code>
  --schemaVersion: string # The schema version of the feedType for the schedule. This field is required if the <strong>feedType</strong> has a schema version. <br /><br />This field is available as specified by the template (<strong>scheduleTemplateId</strong>). The template can specify this field as optional or required, and optionally provides a default value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedule/($schedule_id)")
  let body = {preferredTriggerDayOfMonth: $preferredTriggerDayOfMonth, preferredTriggerDayOfWeek: $preferredTriggerDayOfWeek, preferredTriggerHour: $preferredTriggerHour, scheduleEndDate: $scheduleEndDate, scheduleName: $scheduleName, scheduleStartDate: $scheduleStartDate, schemaVersion: $schemaVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method downloads the latest result file generated by the schedule. The response of this call is a compressed or uncompressed CSV, XML, or JSON file, with the applicable file extension (for example: csv.gz). Specify the <strong>schedule_id</strong> path parameter to download its last generated file.
#
# GET /schedule/{schedule_id}/download_result_file
# operationId: getLatestResultFile
export def "schedule-download-result-file get" [
  schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedule/($schedule_id)/download_result_file")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves an array containing the details and status of all schedule templates based on the specified <strong>feed_type</strong>. Use this method to find a schedule template if you do not know the <strong>schedule_template_id</strong>.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed-type: string # The feed type of the schedule templates to retrieve.
  --limit: string # The maximum number of schedule templates that can be returned on each page of the paginated response. Use this parameter in conjunction with the <strong>offset</strong> parameter to control the pagination of the output. <p> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span></p><p>For example, if <strong>offset</strong> is set to 10 and <strong>limit</strong> is set to 10, the call retrieves schedule templates 11 thru 20 from the result set.</p><p>If this parameter is omitted, the default value is used. <br /><br /><b>Default: </b> 10 <br /><br /><b>Maximum: </b>500
  --offset: string # The number of schedule templates to skip in the result set before returning the first template in the paginated response. <p>Combine <strong>offset</strong> with the <strong>limit</strong> query parameter to control the items returned in the response. For example, if you supply an <strong>offset</strong> of <code>0</code> and a <strong>limit</strong> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <strong>offset</strong> is <code>10</code> and <strong>limit</strong> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned.<br /><br /><b>Default: </b>0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, scheduleTemplates: table<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: list>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedule_template" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves the details of the specified template. Specify the template to retrieve using the <strong>schedule_template_id</strong> path parameter. Use the <strong>getScheduleTemplates</strong> method to find a schedule template if you do not know the <strong>schedule_template_id</strong>.
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<feedType: string, frequency: string, name: string, scheduleTemplateId: string, status: string, supportedConfigurations: table<defaultValue: string, property: string, usage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/schedule_template/($schedule_template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method returns the details and status for an array of tasks based on a specified <strong>feed_type</strong> or <strong>scheduledId</strong>. Specifying both <strong>feed_type</strong> and <strong>scheduledId</strong> results in an error. Since schedules are based on feed types, you can specify a schedule (<strong>schedule_id</strong>) that returns the needed <strong>feed_type</strong>.<br /><br />If specifying the <strong>feed_type</strong>, limit which tasks are returned by specifying filters, such as the creation date range or period of time using <strong>look_back_days</strong>. Also, by specifying the <strong>feed_type</strong>, both on-demand and scheduled reports are returned.<br /><br />If specifying a <strong>scheduledId</strong>, the schedule template (that the schedule ID is based on) determines which tasks are returned (see <strong>schedule_id</strong> for additional information). Each <strong>scheduledId</strong> applies to one <strong>feed_type</strong>. 
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range: string # Specifies the range of task creation dates used to filter the results. The results are filtered to include only tasks with a creation date that is equal to this date or is within specified range. Only tasks that are less than 90 days can be retrieved. <p> <span class="tablenote"><strong>Note:</strong> Maximum date range window size is 90 days.</span></p> <br /><b>Valid Format (UTC):</b><code>yyyy-MM-ddThh:mm:ss.SSSZ..yyyy-MM-ddThh:mm:ss.SSSZ </code><br /><br />For example: Tasks created on September 8, 2019<br /> <code>2019-09-08T00:00:00.000Z..2019-09-09T00:00:00.000Z</code>
  --feed-type: string # The feed type associated with the tasks to be returned. Only use a <strong>feedType</strong> that is available for your API: <ul><li>Order Feeds: <code>LMS_ORDER_ACK, LMS_ORDER_REPORT</code></li><li>Large Merchant Services (LMS) Feeds: See <a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl" target="_blank">Available FeedTypes</a></li></ul><br/>Do not use with the <strong>schedule_id</strong> parameter. Since schedules are based on feed types, you can specify a schedule (<strong>schedule_id</strong>) that returns the needed <strong>feed_type</strong>.
  --limit: string # The maximum number of tasks that can be returned on each page of the paginated response. Use this parameter in conjunction with the <strong>offset</strong> parameter to control the pagination of the output. <p> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span></p><p>For example, if <strong>offset</strong> is set to 10 and <strong>limit</strong> is set to 10, the call retrieves tasks 11 thru 20 from the result set.</p><p>If this parameter is omitted, the default value is used. <br /><br /><b>Default: </b> 10 <br /><br /><b>Maximum: </b>500
  --look-back-days: string # The number of previous days in which to search for tasks. Do not use with the <code>date_range</code> parameter. If both <code>date_range</code> and <code>look_back_days</code> are omitted, this parameter's default value is used.  <br /><br /><b>Default: </b> 7 <br /><br /><b>Range: </b> 1-90 (inclusive)
  --offset: string # The number of tasks to skip in the result set before returning the first task in the paginated response. <p>Combine <strong>offset</strong> with the <strong>limit</strong> query parameter to control the items returned in the response. For example, if you supply an <strong>offset</strong> of <code>0</code> and a <strong>limit</strong> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <strong>offset</strong> is <code>10</code> and <strong>limit</strong> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set. If this query parameter is not set, the default value is used and the first page of records is returned. <br /><br /><b>Default: </b>0
  --schedule-id: string # The schedule ID associated with the task. A schedule periodically generates a report for the feed type specified by the schedule template (see <strong>scheduleTemplateId</strong> in <strong>createSchedule</strong>). Do not use with the <strong>feed_type</strong> parameter. Since schedules are based on feed types, you can specify a schedule (<strong>schedule_id</strong>) that returns the needed <strong>feed_type</strong>.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, tasks: table<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_range" $date_range "scalar") (serialize-qp "feed_type" $feed_type "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "look_back_days" $look_back_days "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "schedule_id" $schedule_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method creates an upload task or a download task without filter criteria. When using this method, specify the <b> feedType</b> and the feed file <b> schemaVersion</b>. The feed type specified sets the task as a download or an upload task.  <p>For details about the upload and download flows, see <a href="/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html">Working with Order Feeds</a> in the Selling Integration Guide.</p><p> <span class="tablenote"><strong>Note:</strong> The scope depends on the feed type. An error message results when an unsupported scope or feed type is specified.</span></p><p>The following list contains this method's authorization scopes and their corresponding feed types:</p><ul><li>https://api.ebay.com/oauth/api_scope/sell.inventory: See <a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl" target="_blank">LMS FeedTypes</a></li><li>https://api.ebay.com/oauth/api_scope/sell.fulfillment: LMS_ORDER_ACK (specify for upload tasks). Also see <a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl" target="_blank">LMS FeedTypes</a></li><li>https://api.ebay.com/oauth/api_scope/sell.marketing: None*</li><li>https://api.ebay.com/oauth/api_scope/commerce.catalog.readonly: None*</li></ul><p>* Reserved for future release</p>
#
# POST /task
# operationId: createTask
export def "task createTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-EBAY-C-MARKETPLACE-ID: string # The ID of the eBay marketplace where the item is hosted. <p> <span class="tablenote"><strong>Note:</strong> This value is case sensitive.</span></p><p>For example:</p><p><code>X-EBAY-C-MARKETPLACE-ID:EBAY_US</code></p><p>This identifies the eBay marketplace that applies to this task. See <a href="/api-docs/sell/feed/types/bas:MarketplaceIdEnum">MarketplaceIdEnum</a>.</p>
  --feedType: string # The feed type associated with the task. Only use a <strong>feedType</strong> that is available for your API. Available feed types:<ul><li><a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#trading-upload-feed-types" target="_blank">Inventory upload feed types</a></li><li><a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#merchant-data-upload-feed-types" target="_blank">Fulfillment upload feed types</a></li><li><a href="/api-docs/sell/static/feed/fx-feeds-quick-reference.html#availabl" target="_blank">Seller Hub feed types</a></li></ul>
  --schemaVersion: string # The schemaVersion/version number of the file format (use the schema version of the API to which you are programming):<ul><li><a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Version" target="_blank">Version Details / Schema Version</a></li><li><a href="/api-docs/sell/static/feed/fx-feeds-quick-reference.html#schema" target="_blank">Seller Hub feed schema version</a></li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/task")
  let body = {feedType: $feedType, schemaVersion: $schemaVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method retrieves the details and status of the specified task. The input is <strong>task_id</strong>. <br /><br />For details of how this method is used, see <a href="/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html">Working with Order Feeds</a> in the Selling Integration Guide. 
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completionDate: string, creationDate: string, detailHref: string, feedType: string, schemaVersion: string, status: string, taskId: string, uploadSummary: record<failureCount: int, successCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method downloads the file previously uploaded using <strong>uploadFile</strong>. Specify the task_id from the <strong>uploadFile</strong> call. <p><span class="tablenote"><strong>Note:</strong> With respect to LMS, this method applies to all feed types except <code>LMS_ORDER_REPORT</code> and <code>LMS_ACTIVE_INVENTORY_REPORT</code>. See <a href="/api-docs/sell/static/feed/lms-feeds.html">LMS API Feeds</a> in the Selling Integration Guide.</span></p>
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task/($task_id)/download_input_file")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method retrieves the generated file that is associated with the specified task ID. The response of this call is a compressed or uncompressed CSV, XML, or JSON file, with the applicable file extension (for example: csv.gz). <p>For details about how this method is used, see <a href="/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html">Working with Order Feeds</a> in the Selling Integration Guide. </p><p><span class="tablenote"><strong>Note:</strong> The status of the task to retrieve must be in the COMPLETED or COMPLETED_WITH_ERROR state before this method can retrieve the file. You can use the getTask or getTasks method to retrieve the status of the task.</span></p>
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task/($task_id)/download_result_file")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method associates the specified file with the specified task ID and uploads the input file. After the file has been uploaded, the processing of the file begins. <br /><br />Reports often take time to generate and it's common for this method to return an HTTP status of 202, which indicates the report is being generated. Use the <b> getTask</b> with the task ID or <b> getTasks</b> to determine the status of a report. <br /><br />The status flow is <code>QUEUED</code> &gt; <code>IN_PROCESS</code> &gt; <code>COMPLETED</code> or <code>COMPLETED_WITH_ERROR</code>. When the status is <code>COMPLETED</code> or <code>COMPLETED_WITH_ERROR</code>, this indicates the file has been processed and the order report can be downloaded. If there are errors, they will be indicated in the report file. <br /><br />For details of how this method is used in the upload flow, see <a href="/api-docs/sell/static/orders/generating-and-retrieving-order-reports.html">Working with Order Feeds</a> in the Selling Integration Guide. <p><span class="tablenote"><strong>Note:</strong> This method applies to all Seller Hub feed types and LMS feed types except <code>LMS_ORDER_REPORT</code> and <code>LMS_ACTIVE_INVENTORY_REPORT</code>. See <a href="/api-docs/sell/static/feed/lms-feeds-quick-reference.html#Availabl" target="_blank">LMS feed types</a> and <a href="/api-docs/sell/static/feed/fx-feeds-quick-reference.html#availabl" target="_blank">Seller Hub feed types</a>.</span></p><p> <span class="tablenote"><b>Note:</b> You must use a <strong>Content-Type</strong> header with its value set to "<strong>multipart/form-data</strong>". See <a href="/api-docs/sell/feed/resources/task/methods/uploadFile#h2-samples">Samples</a> for information.</span></p>
#
# POST /task/{task_id}/upload_file
# operationId: uploadFile
export def "task-upload-file uploadFile" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --creationDate: string # The file creation date. <br /><br /><b> Format: </b> UTC <code>yyyy-MM-ddThh:mm:ss.SSSZ</code><p><b>For example:</b><p>Created on September 8, 2019</p><p><code>2019-09-08T00:00:00.000Z</code></p>
  --fileName: string # The name of the file including its extension (for example, xml or csv) to be uploaded.
  --modificationDate: string # The file modified date. <br /><br /><b> Format: </b> UTC <code>yyyy-MM-ddThh:mm:ss.SSSZ</code><p><b>For example:</b><p>Created on September 9, 2019</p><p><code>2019-09-09T00:00:00.000Z</code></p>
  --name: string # A content identifier. The only presently supported name is <code>file</code>.
  --parameters: record # The parameters you want associated with the file.
  --readDate: string # The date you read the file. <br /><br /><b> Format: </b> UTC <code>yyyy-MM-ddThh:mm:ss.SSSZ</code><p><b>For example:</b><p>Created on September 10, 2019</p><p><code>2019-09-10T00:00:00.000Z</code></p>
  --size: int # The size of the file. (format: int32)
  --type: string # The file type. The only presently supported type is <code>form-data</code>.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task/($task_id)/upload_file")
  let body = {creationDate: $creationDate, fileName: $fileName, modificationDate: $modificationDate, name: $name, parameters: $parameters, readDate: $readDate, size: $size, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}
