# Auto-generated client for ecwid vapi-v2
# Source: https://api.apis.guru/v2/specs/cloud-elements.com/ecwid/api-v2/swagger.json
# Auth: --token flag or $env.ECWID_TOKEN

const BASE_URL = "https://api.cloud-elements.com/elements/api-v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ECWID_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.cloud-elements.com/elements/api-v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["application/json" "application/jsonl" "txt/csv"] }
def accept-completer [] { ["application/json" "application/jsonl" "text/csv"] }
def Elements-Version-completer [] { ["Helium" "Hydrogen"] }
def accept-completer-1 [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bulk-download createBulkDownload" } } | get name | first)
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

# Create a new bulk download job (asynchronous)
#
# POST /bulk/download
# operationId: createBulkDownload
# --docsHubDetails shape: {instanceId?: string, path?: string}
# --query shape: {anyKey?: string}
export def "bulk-download createBulkDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --apiLimit: int # format: int32
  --continueFromJobId: int # format: int32
  --docsHubDetails: record # shape: {instanceId?: string, path?: string}
  --filterDateField: string
  --filterNulls: oneof<nothing, bool>
  format: string@format-completer
  --body-from: string # format: date-time
  --limit: int # format: int32
  --notificationUrl: string
  objectName: string
  --pageSize: int # format: int32
  --query: record # shape: {anyKey?: string}
  --selectFields: string
  --body-to: string # format: date-time
  --body-where: string
]: any -> record<id: string, instance_id: float, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk/download")
  let body = {apiLimit: $apiLimit, continueFromJobId: $continueFromJobId, docsHubDetails: $docsHubDetails, filterDateField: $filterDateField, filterNulls: $filterNulls, format: $format, from: $body_from, limit: $limit, notificationUrl: $notificationUrl, objectName: $objectName, pageSize: $pageSize, query: $query, selectFields: $selectFields, to: $body_to, where: $body_where} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch all the bulk jobs for an instance
#
# GET /bulk/jobs
# operationId: getBulkJobs
export def "bulk-jobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query. For example to get all upload jobs the expression would be where=job_direction='UPLOAD'. The following fields are valid search fields 'object_name', 'job_status', 'job_direction', 'record_count'
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --pageSize: int # The page size for pagination, which defaults to 200 if not supplied (format: int64)
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<completion_time: int, createdDate: int, error_count: int, fileFormat: string, id: int, instanceId: int, job_direction: string, job_query: string, job_reset_attempt: int, job_state: string, notification_url: string, object_name: string, record_count: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk/jobs" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an asynchronous bulk query job.
#
# POST /bulk/query
# operationId: createBulkQuery
export def "bulk-query createBulkQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The CEQL query. When this parameter is omitted, all objects of the given type are returned via the bulk job. Endpoint limiters may still apply.
  --lastRunDate: string # The last time this query was run. This is optional. You can also have this parameter in the query and leave this blank - optional eg. '2014-10-06T13:22:17-08:00'
  --qp-from: string # The created/updated date of the object to filter on - optional eg. '2014-10-06T13:22:17-08:00'
  --qp-to: string # The created/updated date of the object to filter on - optional eg. '2014-10-06T13:22:17-08:00'
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --Elements-Async-Callback-Url: string # The Url to send the notification to when the Job is completed
  --metaData: string # Optional JSON MetaData that contains callback-payload and fileName, ex: {"callback-payload" : <Json> , "fileName" : "{Date format}_Name of the file"}. If the fileName is MyFile then pass metadata as {"fileName" : "{yyyy-MM-dd HH:mm:ss}_MyFile"}. The valid date formats are "yyyy-MM-dd'T'HH:mm:ssXXX", "yyyy-MM-dd'T'HH:mm:ss'Z'", "yyyy-MM-dd'T'HH:mm:ss.SXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd HH:mm:ss", "yyyy.MM.dd G 'at' HH:mm:ss z", "h:mm a", "yyyyy.MMMMM.dd GGG hh:mm aaa" and "yyMMddHHmmssZ". callback-payload - is passed back in bulk job notification 
]: any -> record<id: string, instance_id: float, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lastRunDate" $lastRunDate "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk/query" $qp)
  let body = {metaData: $metaData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Elements-Async-Callback-Url": $Elements_Async_Callback_Url} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Cancel an asynchronous bulk query job.
#
# PUT /bulk/{id}/cancel
# operationId: replaceBulkCancel
export def "bulk-cancel replaceBulkCancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk/($id)/cancel")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the errors of a bulk job.
#
# GET /bulk/{id}/errors
# operationId: getBulkErrors
export def "bulk-errors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The page size for pagination, which defaults to 200 if not supplied (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bulk/($id)/errors" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the status of a bulk job.
#
# GET /bulk/{id}/status
# operationId: getBulkStatus
export def "bulk-status get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<batchId: float, message: string, numOfLeadsProcessed: float, numOfRowsFailed: float, numOfRowsWithWarning: float, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk/($id)/status")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the results of an asynchronous bulk query.
#
# GET /bulk/{id}/{objectName}
# operationId: getBulkByObjectName
export def "bulk get" [
  id: string
  objectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk/($id)/($objectName)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "text/csv")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a file of objects to be bulk uploaded to the provider.
#
# POST /bulk/{objectName}
# operationId: createBulkByObjectName
export def "bulk createBulkByObjectName" [
  objectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --Elements-Async-Callback-Url: string # The Url to send the notification to when the Job is completed
  --metaData: string # Optional JSON MetaData that contains callback-payload, path or format, ex: {"path" :&lt;path for the sub resource&gt;, "format": &lt;json/csv&gt;, "callback-payload":&lt;json&gt;}. path - is passed to the endpoint for bulk loading the data into a nested object. Optional JSON Metadata that contains identifierFieldName, action, listId or campaignId. The identifierField name is used for upserts and the optional fields like listId or campaignId. Example: {"listId":"1014","action":"upsert"}. If the Upload format is JSON pass metadata as {"format":"json"}. callback-payload - is passed back in bulk job notification 
  --file: path # The file of objects to bulk load. If the JSON file upload, each JSON record should be in a single line
]: any -> record<id: string, instanceId: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulk/($objectName)")
  let body = {metaData: $metaData, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Elements-Async-Callback-Url": $Elements_Async_Callback_Url} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Find customers in the eCommerce system, using the provided CEQL search expression. If no search expression is provided, all records will be retrieved
#
# GET /customers
# operationId: getCustomers
export def "customers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). <p>Supported search terms: customer_id and customer_email. All other search criteria are ignored. NOTE: When searching by customer_id, do not quote the value (ex: customer_id=15693430), as the ID is a number rather than a string.  When searching by email, quote the value (ex: customer_email='a@b.c'), as the email parameter is a string
  --pageSize: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: list<record>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new customer in eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Customer' model are those required to create a new customer
#
# POST /customers
# operationId: createCustomer
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --shippingAddresses item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
export def "customers createCustomer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --billingPerson: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --customerGroupId: int # format: int64
  email: string # customer email
  --password: string # customer password
  --shippingAddresses: list # item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --taxExempt: oneof<nothing, bool>
  --taxId: float # format: double
  --taxIdValid: oneof<nothing, bool>
]: any -> record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let body = {billingPerson: $billingPerson, customerGroupId: $customerGroupId, email: $email, password: $password, shippingAddresses: $shippingAddresses, taxExempt: $taxExempt, taxId: $taxId, taxIdValid: $taxIdValid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a customer associated with a given ID from your eCommerce system. Specifying a customer associated with a given ID that does not exist will result in an error message
#
# DELETE /customers/{id}
# operationId: deleteCustomerById
export def "customers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a customer associated with a given ID from the eCommerce system. Specifying a customer with an ID that does not exist will result in an error response
#
# GET /customers/{id}
# operationId: getCustomerById
export def "customers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an customer associated with a given ID in the eCommerce system.The update API uses the PATCH HTTP verb, so only those fields provided in the customer object will be updated, and those fields not provided will be left alone. Updating a customer with a specified ID that does not exist will result in an error response
#
# PATCH /customers/{id}
# operationId: updateCustomerById
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --shippingAddresses item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
export def "customers updateCustomerById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --billingPerson: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --customerGroupId: int # format: int64
  --email: string # customer email
  --password: string # customer password
  --shippingAddresses: list # item shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --taxExempt: oneof<nothing, bool>
  --taxId: float # format: double
  --taxIdValid: oneof<nothing, bool>
]: any -> record<billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, customerGroupId: int, customerGroupName: string, email: string, id: int, name: string, registered: string, shippingAddresses: table<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, taxExempt: bool, taxId: float, taxIdValid: bool, totalOrderCount: float, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($id)")
  let body = {billingPerson: $billingPerson, customerGroupId: $customerGroupId, email: $email, password: $password, shippingAddresses: $shippingAddresses, taxExempt: $taxExempt, taxId: $taxId, taxIdValid: $taxIdValid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Find orders in the customer associated with a given ID. If the customer does not exist, an error response will be returned. If no orders are found in the given customer then an empty array will be returned
#
# GET /customers/{id}/orders
# operationId: getCustomersOrders
export def "customers-orders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($id)/orders" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all the available objects.
#
# GET /objects
# operationId: getObjects
export def "objects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --Elements-Version: string@Elements-Version-completer # Elements Version to be used for getting metadata, possible options are Hydrogen, Helium. Default value is Hydrogen
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/objects")
  let extra_headers = {"Authorization": $Authorization, "Elements-Version": $Elements_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get swagger docs for an object.
#
# GET /objects/{objectName}/docs
# operationId: getObjectsObjectNameDocs
export def "objects-docs get" [
  objectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --discovery: oneof<nothing, bool> # Include discovery metadata in definitions
  --resolveReferences: oneof<nothing, bool> # Optionally resolve swagger references for an inline object definition
  --basic: oneof<nothing, bool> # Include only OpenAPI / Swagger properties in definitions
  --version: string # The element swagger version to get the corresponding element swagger, Passing in "-1" gives latest element swagger (default: -1)
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<basePath: string, definitions: record<definition_name: record<properties: record>>, host: string, info: record<contact: record<email: string>, title: string, version: string>, paths: record<_contacts: record<post: record>>, schemes: list<string>, swagger: string, tags: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "discovery" $discovery "scalar") (serialize-qp "resolveReferences" $resolveReferences "scalar") (serialize-qp "basic" $basic "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($objectName)/docs" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all the field for an object.
#
# GET /objects/{objectName}/metadata
# operationId: getObjectsObjectNameMetadata
export def "objects-metadata get" [
  objectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --Elements-Version: string@Elements-Version-completer # Elements Version to be used for getting metadata, possible options are Hydrogen, Helium. Default value is Hydrogen
]: nothing -> record<fields: table<mask: string, type: string, vendorDisplayName: string, vendorPath: string, vendorReadOnly: bool, vendorRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/objects/($objectName)/metadata")
  let extra_headers = {"Authorization": $Authorization, "Elements-Version": $Elements_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find orders in the eCommerce system, using the provided CEQL search expression. If no search expression is provided, all records will be retrieved
#
# GET /orders
# operationId: getOrders
export def "orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). <p>Supported search terms: date, from_date, to_date, from_update_date, to_update_date, order, from_order, to_order, customer_id, customer_email and statuses. All other search criteria are ignored
  --pageSize: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: list<record>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: list<record>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: list<record>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an order in the eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Order' model are those required to create a new order.The paymentStatus can only be AWAITING_PAYMENT or INCOMPLETE.The fulfillmentStatus can only be AWAITING_PROCESSING
#
# POST /orders
# operationId: createOrder
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --items item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
# --shippingOption shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
# --shippingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
export def "orders createOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --billingPerson: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --couponDiscount: float # format: double
  --customerId: float # format: double
  --customerTaxExempt: oneof<nothing, bool>
  --customerTaxId: int # format: int64
  --customerTaxIdValid: oneof<nothing, bool>
  --discount: float # format: double
  --email: string
  fulfillmentStatus: string # AWAITING_PROCESSING, PROCESSING, SHIPPED, DELIVERED, WILL_NOT_DELIVER, RETURNED, READY_FOR_PICKUP
  --globalReferer: string
  --hidden: oneof<nothing, bool>
  --items: list # item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
  --membershipBasedDiscount: float # format: double
  --orderComments: string
  --paymentMethod: string
  --paymentModule: string
  paymentStatus: string # AWAITING_PAYMENT, PAID, CANCELLED, REFUNDED, PARTIALLY_REFUNDED, INCOMPLETE
  --privateAdminNotes: string
  --refererUrl: string
  --reversedTaxApplied: oneof<nothing, bool>
  --sample: oneof<nothing, bool>
  --shippingMethod: string
  --shippingOption: record # shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
  --shippingPerson: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --subtotal: float # format: double
  --tax: float # format: double
  --total: float # format: double
  --totalAndMembershipBasedDiscount: float # format: double
  --volumeDiscount: float # format: double
]: any -> record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let body = {billingPerson: $billingPerson, couponDiscount: $couponDiscount, customerId: $customerId, customerTaxExempt: $customerTaxExempt, customerTaxId: $customerTaxId, customerTaxIdValid: $customerTaxIdValid, discount: $discount, email: $email, fulfillmentStatus: $fulfillmentStatus, globalReferer: $globalReferer, hidden: $hidden, items: $items, membershipBasedDiscount: $membershipBasedDiscount, orderComments: $orderComments, paymentMethod: $paymentMethod, paymentModule: $paymentModule, paymentStatus: $paymentStatus, privateAdminNotes: $privateAdminNotes, refererUrl: $refererUrl, reversedTaxApplied: $reversedTaxApplied, sample: $sample, shippingMethod: $shippingMethod, shippingOption: $shippingOption, shippingPerson: $shippingPerson, subtotal: $subtotal, tax: $tax, total: $total, totalAndMembershipBasedDiscount: $totalAndMembershipBasedDiscount, volumeDiscount: $volumeDiscount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an order associated with a given ID from your eCommerce system. Specifying an order associated with a given ID that does not exist will result in an error message
#
# DELETE /orders/{id}
# operationId: deleteOrderById
export def "orders delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an order associated with a given ID from the eCommerce system. Specifying an order with an ID that does not exist will result in an error response
#
# GET /orders/{id}
# operationId: getOrderById
export def "orders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an order associated with a given ID in the eCommerce system. The update API uses the PATCH HTTP verb, so only those fields provided in the order object will be updated, and those fields not provided will be left alone. Updating an order with a specified ID that does not exist will result in an error response</strong>
#
# PATCH /orders/{id}
# operationId: updateOrderById
# --billingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --items item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
# --shippingOption shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
# --shippingPerson shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
# --taxesOnShipping item shape: {name?: string, total?: float, value?: float}
export def "orders updateOrderById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # An action to perform on the order: cancel, reopen or close. If left blank then the order is updated but no action is taken
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --billingPerson: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --couponDiscount: float # format: double
  --customerId: float # format: double
  --customerTaxExempt: oneof<nothing, bool>
  --customerTaxId: int # format: int64
  --customerTaxIdValid: oneof<nothing, bool>
  --discount: float # format: double
  --email: string
  --fulfillmentStatus: string # AWAITING_PROCESSING, PROCESSING, SHIPPED, DELIVERED, WILL_NOT_DELIVER, RETURNED, READY_FOR_PICKUP
  --globalReferer: string
  --hidden: oneof<nothing, bool>
  --items: list # item shape: {categoryId?: int, couponApplied?: bool, digital?: bool, fixedShippingRate?: float, fixedShippingRateOnly?: bool, hdThumbnailUrl?: string, id?: int, imageUrl?: string, isShippingRequired?: bool, name?: string, price?: float, productAvailable?: bool, productId?: int, productPrice?: float, quantity?: int, quantityInStock?: float, shipping?: float, sku?: string, smallThumbnailUrl?: string, tax?: float, taxes?: list, trackQuantity?: bool, weight?: float}
  --membershipBasedDiscount: float # format: double
  --orderComments: string
  --paymentModule: string
  --paymentStatus: string # AWAITING_PAYMENT, PAID, CANCELLED, REFUNDED, PARTIALLY_REFUNDED, INCOMPLETE
  --privateAdminNotes: string
  --refererUrl: string
  --reversedTaxApplied: oneof<nothing, bool>
  --sample: oneof<nothing, bool>
  --shippingMethod: string
  --shippingOption: record # shape: {estimatedTransitTime?: string, isPickup?: bool, shippingCarrierName?: string, shippingMethodName?: string, shippingRate?: float}
  --shippingPerson: record # shape: {city?: string, companyName?: string, countryCode?: string, countryName?: string, name?: string, phone?: string, postalCode?: string, stateName?: string, stateOrProvinceCode?: string, stateOrProvinceName?: string, street?: string}
  --subtotal: float # format: double
  --tax: float # format: double
  --taxesOnShipping: list # item shape: {name?: string, total?: float, value?: float}
  --total: float # format: double
  --totalAndMembershipBasedDiscount: float # format: double
  --volumeDiscount: float # format: double
]: any -> record<additionalInfo: record<google_customer_id: string>, billingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, couponDiscount: float, createDate: string, createTimestamp: float, customerId: float, customerTaxExempt: bool, customerTaxId: int, customerTaxIdValid: bool, discount: float, email: string, fulfillmentStatus: string, globalReferer: string, handlingFee: record<description: string, name: string, value: float>, hidden: bool, ipAddress: string, items: table<categoryId: int, couponApplied: bool, digital: bool, fixedShippingRate: float, fixedShippingRateOnly: bool, hdThumbnailUrl: string, id: int, imageUrl: string, isShippingRequired: bool, name: string, price: float, productAvailable: bool, productId: int, productPrice: float, quantity: int, quantityInStock: float, shipping: float, sku: string, smallThumbnailUrl: string, tax: float, taxes: list, trackQuantity: bool, weight: float>, lastChangeDate: string, membershipBasedDiscount: float, orderComments: string, orderNumber: int, paymentMethod: string, paymentModule: string, paymentStatus: string, privateAdminNotes: string, refererUrl: string, refundedAmount: float, refunds: table<amount: float, date: string, reason: string, source: string>, reversedTaxApplied: bool, sample: bool, shippingMethod: string, shippingOption: record<estimatedTransitTime: string, isPickup: bool, shippingCarrierName: string, shippingMethodName: string, shippingRate: float>, shippingPerson: record<city: string, companyName: string, countryCode: string, countryName: string, name: string, phone: string, postalCode: string, stateName: string, stateOrProvinceCode: string, stateOrProvinceName: string, street: string>, subtotal: float, tax: float, taxesOnShipping: table<name: string, total: float, value: float>, total: float, totalAndMembershipBasedDiscount: float, trackingNumber: string, updateDate: string, updateTimestamp: float, usdTotal: float, vendorNumber: float, vendorOrderNumber: string, volumeDiscount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/($id)" $qp)
  let body = {billingPerson: $billingPerson, couponDiscount: $couponDiscount, customerId: $customerId, customerTaxExempt: $customerTaxExempt, customerTaxId: $customerTaxId, customerTaxIdValid: $customerTaxIdValid, discount: $discount, email: $email, fulfillmentStatus: $fulfillmentStatus, globalReferer: $globalReferer, hidden: $hidden, items: $items, membershipBasedDiscount: $membershipBasedDiscount, orderComments: $orderComments, paymentModule: $paymentModule, paymentStatus: $paymentStatus, privateAdminNotes: $privateAdminNotes, refererUrl: $refererUrl, reversedTaxApplied: $reversedTaxApplied, sample: $sample, shippingMethod: $shippingMethod, shippingOption: $shippingOption, shippingPerson: $shippingPerson, subtotal: $subtotal, tax: $tax, taxesOnShipping: $taxesOnShipping, total: $total, totalAndMembershipBasedDiscount: $totalAndMembershipBasedDiscount, volumeDiscount: $volumeDiscount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the payments in the eCommerce system for the specified order
#
# GET /orders/{orderId}/payments
# operationId: getOrdersPayments
export def "orders-payments get" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<paymentMethod: string, paymentStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/($orderId)/payments" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the refunds in the eCommerce system for the specified order
#
# GET /orders/{orderId}/refunds
# operationId: getOrdersRefunds
export def "orders-refunds get" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<paymentMethod: string, paymentStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/($orderId)/refunds" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping the Element to confirm that the Hub Element has a heartbeat.  If the Element does not have a heartbeat, an error message will be returned.
#
# GET /ping
# operationId: getPing
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<dateTime: string, endpoint: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find products in the eCommerce system, using the provided CEQL search expression. The search expression in CEQL is the WHERE clause in a typical SQL query, but without the WHERE keyword.  If no search expression is provided, all records will be retrieved
#
# GET /products
# operationId: getProducts
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression, or the where clause, without the WHERE keyword, in a typical SQL query (i.e. field='value'). <p>Supported search terms: category, hidden_products. All other search criteria are ignored
  --pageSize: int # The number of results to fetch in a given page. When this parameter is omitted, a maximum of 200 results are returned (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<attributes: list<record>, borderInfo: record<dominatingColor: record, homogeneity: bool>, categories: list<record>, categoryIds: list<int>, combinations: list<record>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: list<record>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: list<record>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list>, name: string, options: list<record>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list, relatedCategory: record>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list, enabledMethods: list, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list>, taxes: list<record>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new product in eCommerce system.With the exception of the 'id' field, the required fields indicated in the 'Product' model are those required to create a new product
#
# POST /products
# operationId: createProduct
# --attributes item shape: {id?: int, internalName?: string, name?: string, value?: string}
# --dimensions shape: {height?: float, length?: float, width?: float}
# --favorites shape: {count?: int, displayedCount?: string}
# --galleryImages item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
# --options item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
# --relatedProducts shape: {productIds?: list, relatedCategory?: record}
# --shipping shape: {disabledMethods?: list, enabledMethods?: list, flatRate?: float, methodMarkup?: float, type?: string}
# --tax shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list}
# --taxes item shape: {name?: string, total?: float, value?: float}
# --wholesalePrices shape: {{quantity}?: float}
export def "products createProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --attributes: list # item shape: {id?: int, internalName?: string, name?: string, value?: string}
  --categoryIds: list
  --compareAtPrice: float # Product’s sale price displayed strike-out in the customer (format: double)
  --compareToPrice: float # format: double
  --created: string # format: date-time
  --defaultCategoryId: int # format: int64
  --description: string # Product description in HTML
  --dimensions: record # shape: {height?: float, length?: float, width?: float}
  --enabled: oneof<nothing, bool> # true/false
  --favorites: record # shape: {count?: int, displayedCount?: string}
  --fixedShippingRate: float # format: double
  --fixedShippingRateOnly: oneof<nothing, bool> # true/false
  --galleryImages: list # item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
  --googleItemCondition: string # Google Item Condition Status
  --isShippingRequired: oneof<nothing, bool>
  --name: string # Product title
  --options: list # item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
  --price: float # Base Product price (format: double)
  --productClassId: int # Id of the product type that this product belongs to. (format: int64)
  --quantity: int # Amount of product items in stock. (format: int64)
  --relatedProducts: record # shape: {productIds?: list, relatedCategory?: record}
  --seoDescription: string
  --seoTitle: string
  --shipping: record # shape: {disabledMethods?: list, enabledMethods?: list, flatRate?: float, methodMarkup?: float, type?: string}
  --showOnFrontpage: float # format: double
  --sku: string # Product SKU
  --tax: record # shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list}
  --taxes: list # item shape: {name?: string, total?: float, value?: float}
  --warningLimit: int # format: int64
  --weight: float # Product weight in the units defined in store settings (format: double)
  --wholesalePrices: record # shape: {{quantity}?: float}
]: any -> record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let body = {attributes: $attributes, categoryIds: $categoryIds, compareAtPrice: $compareAtPrice, compareToPrice: $compareToPrice, created: $created, defaultCategoryId: $defaultCategoryId, description: $description, dimensions: $dimensions, enabled: $enabled, favorites: $favorites, fixedShippingRate: $fixedShippingRate, fixedShippingRateOnly: $fixedShippingRateOnly, galleryImages: $galleryImages, googleItemCondition: $googleItemCondition, isShippingRequired: $isShippingRequired, name: $name, options: $options, price: $price, productClassId: $productClassId, quantity: $quantity, relatedProducts: $relatedProducts, seoDescription: $seoDescription, seoTitle: $seoTitle, shipping: $shipping, showOnFrontpage: $showOnFrontpage, sku: $sku, tax: $tax, taxes: $taxes, warningLimit: $warningLimit, weight: $weight, wholesalePrices: $wholesalePrices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a product associated with a given ID from your eCommerce system. Specifying a product associated with a given ID that does not exist will result in an error message
#
# DELETE /products/{id}
# operationId: deleteProductById
export def "products delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a product associated with a given ID from the eCommerce system. Specifying a product with an ID that does not exist will result in an error response
#
# GET /products/{id}
# operationId: getProductById
export def "products get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a product associated with a given ID in the eCommerce system. The update API uses the PATCH HTTP verb, so only those fields provided in the product object will be updated, and those fields not provided will be left alone. Updating a product with a specified ID that does not exist will result in an error response. <p><strong>Update supports the following fields: sku, quantity, trackQuantity, quantityDelta, warningLimit, name, price, weight, tangible, enabled, fixedShippingRateOnly, fixedShippingRate, description, wholesalePrices, compareAtPrice, productClassId</strong>
#
# PATCH /products/{id}
# operationId: updateProductById
# --attributes item shape: {id?: int, internalName?: string, name?: string, value?: string}
# --dimensions shape: {height?: float, length?: float, width?: float}
# --galleryImages item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
# --options item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
# --relatedProducts shape: {productIds?: list, relatedCategory?: record}
# --shipping shape: {disabledMethods?: list, enabledMethods?: list, flatRate?: float, methodMarkup?: float, type?: string}
# --tax shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list}
# --taxes item shape: {name?: string, total?: float, value?: float}
# --wholesalePrices shape: {{quantity}?: float}
export def "products updateProductById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --attributes: list # item shape: {id?: int, internalName?: string, name?: string, value?: string}
  --categoryIds: list
  --compareAtPrice: float # Product’s sale price displayed strike-out in the customer (format: double)
  --compareToPrice: float # format: double
  --defaultCategoryId: int # format: int64
  --description: string # Product description in HTML
  --dimensions: record # shape: {height?: float, length?: float, width?: float}
  --enabled: oneof<nothing, bool> # true/false
  --fixedShippingRate: float # format: double
  --fixedShippingRateOnly: oneof<nothing, bool> # true/false
  --galleryImages: list # item shape: {alt?: string, height?: int, thumbnail?: string, url?: string, width?: int}
  --googleItemCondition: string # Google Item Condition Status
  --isShippingRequired: oneof<nothing, bool>
  --name: string # Product title
  --options: list # item shape: {choices?: list, defaultChoice?: int, name: string, required: bool, type: string}
  --price: float # Base Product price (format: double)
  --productClassId: int # Id of the product type that this product belongs to. (format: int64)
  --quantity: int # Amount of product items in stock. (format: int64)
  --relatedProducts: record # shape: {productIds?: list, relatedCategory?: record}
  --seoDescription: string
  --seoTitle: string
  --shipping: record # shape: {disabledMethods?: list, enabledMethods?: list, flatRate?: float, methodMarkup?: float, type?: string}
  --showOnFrontpage: float # format: double
  --sku: string # Product SKU
  --tax: record # shape: {defaultLocationIncludedTaxRate?: float, enabledManualTaxes?: list}
  --taxes: list # item shape: {name?: string, total?: float, value?: float}
  --warningLimit: int # format: int64
  --weight: float # Product weight in the units defined in store settings (format: double)
  --wholesalePrices: record # shape: {{quantity}?: float}
]: any -> record<attributes: table<id: int, internalName: string, name: string, value: string>, borderInfo: record<dominatingColor: record<alpha: float, blue: float, green: float, red: float>, homogeneity: bool>, categories: table<defaultCategory: bool, description: string, enabled: bool, id: int, name: string, originalImageUrl: string, productCount: int, thumbnailUrl: string, url: string>, categoryIds: list<int>, combinations: table<attributes: list, combinationNumber: float, compareToPrice: float, id: float, price: float, quantity: float, sku: string, unlimited: bool, warningLimit: float, weight: float>, compareAtPrice: float, compareToPrice: float, compareToPriceDiscount: float, compareToPriceDiscountFormatted: string, compareToPriceDiscountPercent: float, compareToPriceDiscountPercentFormatted: string, compareToPriceFormatted: string, createTimestamp: int, created: string, defaultCategoryId: int, defaultCombinationId: float, defaultDisplayedPrice: float, defaultDisplayedPriceFormatted: string, description: string, descriptionTruncated: bool, dimensions: record<height: float, length: float, width: float>, enabled: bool, favorites: record<count: int, displayedCount: string>, files: table<adminUrl: string, description: string, id: float, name: string, size: float>, fixedShippingRate: float, fixedShippingRateOnly: bool, galleryImages: table<alt: string, height: int, thumbnail: string, url: string, width: int>, googleItemCondition: string, hdThumbnailUrl: string, id: int, imageUrl: string, inStock: bool, isSampleProduct: bool, isShippingRequired: bool, media: record<images: list<record>>, name: string, options: table<choices: list, defaultChoice: int, name: string, required: bool, type: string>, originalImage: record<alt: string, height: int, thumbnail: string, url: string, width: int>, originalImageUrl: string, price: float, priceInProductList: float, productClassId: int, quantity: int, quantityDelta: int, relatedProducts: record<productIds: list<float>, relatedCategory: record<categoryId: float, enabled: bool, productCount: float>>, seoDescription: string, seoTitle: string, shipping: record<disabledMethods: list<string>, enabledMethods: list<string>, flatRate: float, methodMarkup: float, type: string>, showOnFrontpage: float, sku: string, smallThumbnailUrl: string, tangible: string, tax: record<defaultLocationIncludedTaxRate: float, enabledManualTaxes: list<int>>, taxes: table<name: string, total: float, value: float>, thumbnailUrl: string, trackQuantity: string, unlimited: bool, updateTimestamp: int, updated: string, url: string, warningLimit: int, weight: float, wholesalePrices: record<_quantity_: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)")
  let body = {attributes: $attributes, categoryIds: $categoryIds, compareAtPrice: $compareAtPrice, compareToPrice: $compareToPrice, defaultCategoryId: $defaultCategoryId, description: $description, dimensions: $dimensions, enabled: $enabled, fixedShippingRate: $fixedShippingRate, fixedShippingRateOnly: $fixedShippingRateOnly, galleryImages: $galleryImages, googleItemCondition: $googleItemCondition, isShippingRequired: $isShippingRequired, name: $name, options: $options, price: $price, productClassId: $productClassId, quantity: $quantity, relatedProducts: $relatedProducts, seoDescription: $seoDescription, seoTitle: $seoTitle, shipping: $shipping, showOnFrontpage: $showOnFrontpage, sku: $sku, tax: $tax, taxes: $taxes, warningLimit: $warningLimit, weight: $weight, wholesalePrices: $wholesalePrices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for {objectName}
#
# GET /{objectName}
# operationId: getByObjectName
export def "object-name get-by-objectName" [
  objectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression.
  --pageSize: int # The page size. Defaults to 200 if not provided. Maximum of 5000. (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($objectName)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an {objectName}
#
# POST /{objectName}
# operationId: createByObjectName
export def "object-name createByObjectName" [
  objectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --objectField: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)")
  let body = {objectField: $objectField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an {objectName}
#
# DELETE /{objectName}/{objectId}
# operationId: deleteObjectNameByObjectId
export def "object-name delete-by-objectName-objectId" [
  objectName: string
  objectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an {objectName}
#
# GET /{objectName}/{objectId}
# operationId: getObjectNameByObjectId
export def "object-name get-by-objectName-objectId" [
  objectName: string
  objectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an {objectName}
#
# PATCH /{objectName}/{objectId}
# operationId: updateObjectNameByObjectId
export def "object-name updateObjectNameByObjectId" [
  objectName: string
  objectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --objectField: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)")
  let body = {objectField: $objectField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an {objectName}
#
# PUT /{objectName}/{objectId}
# operationId: replaceObjectNameByObjectId
export def "object-name replaceObjectNameByObjectId" [
  objectName: string
  objectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --objectField: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)")
  let body = {objectField: $objectField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for {childObjectName}
#
# GET /{objectName}/{objectId}/{childObjectName}
# operationId: getObjectNameByChildObjectName
export def "object-name get-by-objectName-objectId-childObjectName" [
  objectName: string
  objectId: string
  childObjectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # The CEQL search expression.
  --pageSize: int # The page size. Defaults to 200 if not provided. Maximum of 5000. (format: int64)
  --nextPage: string # The next page cursor, taken from the response header: `elements-next-page-token`
  --fields: string # The fields to return on the response. Can be a single field or a comma-separated list of fields
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> table<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "nextPage" $nextPage "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($objectName)/($objectId)/($childObjectName)" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an {objectName}
#
# POST /{objectName}/{objectId}/{childObjectName}
# operationId: createObjectNameByChildObjectName
export def "object-name createObjectNameByChildObjectName" [
  objectName: string
  objectId: string
  childObjectName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --objectField: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)/($childObjectName)")
  let body = {objectField: $objectField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an {childObjectName}
#
# DELETE /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: deleteObjectNameByChildObjectId
export def "object-name delete-by-objectName-childObjectName-objectId-childObjectId" [
  objectName: string
  childObjectName: string
  objectId: string
  childObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)/($childObjectName)/($childObjectId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an {childObjectName}
#
# GET /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: getObjectNameByChildObjectId
export def "object-name get-by-objectName-childObjectName-objectId-childObjectId" [
  objectName: string
  childObjectName: string
  objectId: string
  childObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
]: nothing -> record<objectField: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)/($childObjectName)/($childObjectId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an {childObjectName}
#
# PATCH /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: updateObjectNameByChildObjectId
export def "object-name updateObjectNameByChildObjectId" [
  objectName: string
  childObjectName: string
  objectId: string
  childObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --objectField: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)/($childObjectName)/($childObjectId)")
  let body = {objectField: $objectField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an {childObjectName}
#
# PUT /{objectName}/{objectId}/{childObjectName}/{childObjectId}
# operationId: replaceObjectNameByChildObjectId
export def "object-name replaceObjectNameByChildObjectId" [
  objectName: string
  childObjectName: string
  objectId: string
  childObjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The authorization tokens. The format for the header value is 'Element &lt;token&gt;, User &lt;user secret&gt;'
  --objectField: string
]: any -> record<objectField: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($objectName)/($objectId)/($childObjectName)/($childObjectId)")
  let body = {objectField: $objectField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
