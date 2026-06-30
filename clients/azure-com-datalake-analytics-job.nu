# Auto-generated client for DataLakeAnalyticsJobManagementClient v2017-09-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/datalake-analytics-job/2017-09-01-preview/swagger.json
# Auth: --token flag or $env.DATALAKEANALYTICSJOBMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://{accountName}.azuredatalakeanalytics.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o DATALAKEANALYTICSJOBMANAGEMENTCLIENT_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://{accountName}.azuredatalakeanalytics.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["Hive" "Scope" "USql"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "build-job build" } } | get name | first)
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

# Builds (compiles) the specified job in the specified Data Lake Analytics account for job correctness and validation.
#
# POST /buildJob
# operationId: Job_Build
# --properties shape: {runtimeVersion?: string, script: string, type: string}
export def "build-job build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --name: string # The friendly name of the job to build.
  properties: any # The common Data Lake Analytics job properties for job submission. — shape: {runtimeVersion?: string, script: string, type: string}
  type: string@type-completer # The job type of the current job (Hive, USql, or Scope (for internal use only)).
]: any -> record<errorMessage: table<description: string, details: string, endOffset: int, errorId: string, filePath: string, helpLink: string, innerError: record, internalDiagnostics: string, lineNumber: int, message: string, resolution: string, severity: string, source: string, startOffset: int>, properties: record<runtimeVersion: string, script: string, type: string>, stateAuditRecords: table<details: string, newState: string, requestedByUser: string, timeStamp: string>, degreeOfParallelism: int, degreeOfParallelismPercent: float, endTime: string, hierarchyQueueNode: string, jobId: string, logFilePatterns: list<string>, logFolder: string, name: string, priority: int, related: record<pipelineId: string, pipelineName: string, pipelineUri: string, recurrenceId: string, recurrenceName: string, runId: string>, result: string, startTime: string, state: string, submitTime: string, submitter: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/buildJob" $qp $auth.query)
  let req_body = {"name": $name, "properties": $properties, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the jobs, if any, associated with the specified Data Lake Analytics account. The response includes a link to the next page of results, if any.
#
# GET /jobs
# operationId: Job_List
export def "jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # OData filter. Optional.
  --top: int # The number of items to return. Optional. (format: int32)
  --skip: int # The number of items to skip over before returning elements. Optional. (format: int32)
  --select: string # OData Select statement. Limits the properties on each entry to just those requested, e.g. Categories?$select=CategoryName,Description. Optional.
  --orderby: string # OrderBy clause. One or more comma-separated expressions with an optional "asc" (the default) or "desc" depending on the order you'd like the values sorted, e.g. Categories?$orderby=CategoryName desc. Optional.
  --count: oneof<nothing, bool> # The Boolean value of true or false to request a count of the matching resources included with the resources in the response, e.g. Categories?$count=true. Optional.
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<degreeOfParallelism: int, degreeOfParallelismPercent: float, endTime: string, hierarchyQueueNode: string, jobId: string, logFilePatterns: list, logFolder: string, name: string, priority: int, related: record, result: string, startTime: string, state: string, submitTime: string, submitter: string, tags: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$select" $select "scalar") (serialize-qp "$orderby" $orderby "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jobs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$filter": $filter, "$top": $top, "$skip": $skip, "$select": $select, "$orderby": $orderby, "$count": $count, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the job information for the specified job ID.
#
# GET /jobs/{jobIdentity}
# operationId: Job_Get
export def "jobs get" [
  job_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<errorMessage: table<description: string, details: string, endOffset: int, errorId: string, filePath: string, helpLink: string, innerError: record, internalDiagnostics: string, lineNumber: int, message: string, resolution: string, severity: string, source: string, startOffset: int>, properties: record<runtimeVersion: string, script: string, type: string>, stateAuditRecords: table<details: string, newState: string, requestedByUser: string, timeStamp: string>, degreeOfParallelism: int, degreeOfParallelismPercent: float, endTime: string, hierarchyQueueNode: string, jobId: string, logFilePatterns: list<string>, logFolder: string, name: string, priority: int, related: record<pipelineId: string, pipelineName: string, pipelineUri: string, recurrenceId: string, recurrenceName: string, runId: string>, result: string, startTime: string, state: string, submitTime: string, submitter: string, tags: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_identity | is-empty) { error make --unspanned { msg: "path parameter 'jobIdentity' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_identity: (encode-path-segment $job_identity)} | format pattern "/jobs/{job_identity}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the job information for the specified job ID. (Only for use internally with Scope job type.)
#
# PATCH /jobs/{jobIdentity}
# operationId: Job_Update
export def "jobs update" [
  job_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --degree-of-parallelism: int # The degree of parallelism used for this job. (format: int32)
  --degree-of-parallelism-percent: float # the degree of parallelism in percentage used for this job. (format: double)
  --priority: int # The priority value for the current job. Lower numbers have a higher priority. By default, a job has a priority of 1000. This must be greater than 0. (format: int32)
  --tags: record # The key-value pairs used to add additional metadata to the job information.
]: any -> record<errorMessage: table<description: string, details: string, endOffset: int, errorId: string, filePath: string, helpLink: string, innerError: record, internalDiagnostics: string, lineNumber: int, message: string, resolution: string, severity: string, source: string, startOffset: int>, properties: record<runtimeVersion: string, script: string, type: string>, stateAuditRecords: table<details: string, newState: string, requestedByUser: string, timeStamp: string>, degreeOfParallelism: int, degreeOfParallelismPercent: float, endTime: string, hierarchyQueueNode: string, jobId: string, logFilePatterns: list<string>, logFolder: string, name: string, priority: int, related: record<pipelineId: string, pipelineName: string, pipelineUri: string, recurrenceId: string, recurrenceName: string, runId: string>, result: string, startTime: string, state: string, submitTime: string, submitter: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_identity | is-empty) { error make --unspanned { msg: "path parameter 'jobIdentity' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_identity: (encode-path-segment $job_identity)} | format pattern "/jobs/{job_identity}") $qp $auth.query)
  let req_body = {"degreeOfParallelism": $degree_of_parallelism, "degreeOfParallelismPercent": $degree_of_parallelism_percent, "priority": $priority, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200 201 202]
}

# Submits a job to the specified Data Lake Analytics account.
#
# PUT /jobs/{jobIdentity}
# operationId: Job_Create
# --related shape: {pipelineId?: string, pipelineName?: string, pipelineUri?: string, recurrenceId: string, recurrenceName?: string, runId?: string}
# --properties shape: {runtimeVersion?: string, script: string, type: string}
export def "jobs create" [
  job_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --degree-of-parallelism: int # The degree of parallelism to use for this job. At most one of degreeOfParallelism and degreeOfParallelismPercent should be specified. If none, a default value of 1 will be used for degreeOfParallelism. (format: int32, default: 1)
  --degree-of-parallelism-percent: float # the degree of parallelism in percentage used for this job. At most one of degreeOfParallelism and degreeOfParallelismPercent should be specified. If none, a default value of 1 will be used for degreeOfParallelism. (format: double)
  --log-file-patterns: list<string> # The list of log file name patterns to find in the logFolder. '*' is the only matching character allowed. Example format: jobExecution*.log or *mylog*.txt
  name: string # The friendly name of the job to submit.
  --priority: int # The priority value to use for the current job. Lower numbers have a higher priority. By default, a job has a priority of 1000. This must be greater than 0. (format: int32)
  --related: any # Job relationship information properties including pipeline information, correlation information, etc. — shape: {pipelineId?: string, pipelineName?: string, pipelineUri?: string, recurrenceId: string, recurrenceName?: string, runId?: string}
  properties: any # The common Data Lake Analytics job properties for job submission. — shape: {runtimeVersion?: string, script: string, type: string}
  type: string@type-completer # The job type of the current job (Hive, USql, or Scope (for internal use only)).
]: any -> record<errorMessage: table<description: string, details: string, endOffset: int, errorId: string, filePath: string, helpLink: string, innerError: record, internalDiagnostics: string, lineNumber: int, message: string, resolution: string, severity: string, source: string, startOffset: int>, properties: record<runtimeVersion: string, script: string, type: string>, stateAuditRecords: table<details: string, newState: string, requestedByUser: string, timeStamp: string>, degreeOfParallelism: int, degreeOfParallelismPercent: float, endTime: string, hierarchyQueueNode: string, jobId: string, logFilePatterns: list<string>, logFolder: string, name: string, priority: int, related: record<pipelineId: string, pipelineName: string, pipelineUri: string, recurrenceId: string, recurrenceName: string, runId: string>, result: string, startTime: string, state: string, submitTime: string, submitter: string, tags: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_identity | is-empty) { error make --unspanned { msg: "path parameter 'jobIdentity' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_identity: (encode-path-segment $job_identity)} | format pattern "/jobs/{job_identity}") $qp $auth.query)
  let req_body = {"degreeOfParallelism": $degree_of_parallelism, "degreeOfParallelismPercent": $degree_of_parallelism_percent, "logFilePatterns": $log_file_patterns, "name": $name, "priority": $priority, "related": $related, "properties": $properties, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancels the running job specified by the job ID.
#
# POST /jobs/{jobIdentity}/CancelJob
# operationId: Job_Cancel
export def "jobs-cancel-job cancel" [
  job_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_identity | is-empty) { error make --unspanned { msg: "path parameter 'jobIdentity' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_identity: (encode-path-segment $job_identity)} | format pattern "/jobs/{job_identity}/CancelJob") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Gets the job debug data information specified by the job ID.
#
# GET /jobs/{jobIdentity}/GetDebugDataPath
# operationId: Job_GetDebugDataPath
export def "jobs-get-debug-data-path get" [
  job_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<command: string, jobId: string, paths: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_identity | is-empty) { error make --unspanned { msg: "path parameter 'jobIdentity' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_identity: (encode-path-segment $job_identity)} | format pattern "/jobs/{job_identity}/GetDebugDataPath") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets statistics of the specified job.
#
# GET /jobs/{jobIdentity}/GetStatistics
# operationId: Job_GetStatistics
export def "jobs-get-statistics get" [
  job_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<finalizingTimeUtc: string, lastUpdateTimeUtc: string, stages: table<allocatedContainerCpuCoreCount: record, allocatedContainerMemSize: record, dataRead: int, dataReadCrossPod: int, dataReadIntraPod: int, dataToRead: int, dataWritten: int, duplicateDiscardCount: int, estimatedVertexCpuCoreCount: int, estimatedVertexMemSize: int, estimatedVertexPeakCpuCoreCount: int, failedCount: int, maxDataReadVertex: record, maxExecutionTimeVertex: record, maxPeakMemUsageVertex: record, maxVertexDataRead: int, minVertexDataRead: int, readFailureCount: int, revocationCount: int, runningCount: int, scheduledCount: int, stageName: string, succeededCount: int, tempDataWritten: int, totalCount: int, totalExecutionTime: string, totalFailedTime: string, totalPeakMemUsage: int, totalProgress: int, totalSucceededTime: string, usedVertexCpuCoreCount: record, usedVertexPeakMemSize: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_identity | is-empty) { error make --unspanned { msg: "path parameter 'jobIdentity' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_identity: (encode-path-segment $job_identity)} | format pattern "/jobs/{job_identity}/GetStatistics") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Pauses the specified job and places it back in the job queue, behind other jobs of equal or higher importance, based on priority. (Only for use internally with Scope job type.)
#
# POST /jobs/{jobIdentity}/YieldJob
# operationId: Job_Yield
export def "jobs-yield-job create" [
  job_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($job_identity | is-empty) { error make --unspanned { msg: "path parameter 'jobIdentity' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({job_identity: (encode-path-segment $job_identity)} | format pattern "/jobs/{job_identity}/YieldJob") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200 202 204]
}

# Lists all pipelines.
#
# GET /pipelines
# operationId: Pipeline_List
export def "pipelines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date-time: string # The start date for when to get the list of pipelines. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --end-date-time: string # The end date for when to get the list of pipelines. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<auHoursCanceled: float, auHoursFailed: float, auHoursSucceeded: float, lastSubmitTime: string, numJobsCanceled: int, numJobsFailed: int, numJobsSucceeded: int, pipelineId: string, pipelineName: string, pipelineUri: string, recurrences: list, runs: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pipelines" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDateTime": $start_date_time, "endDateTime": $end_date_time, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the Pipeline information for the specified pipeline ID.
#
# GET /pipelines/{pipelineIdentity}
# operationId: Pipeline_Get
export def "pipelines get" [
  pipeline_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date-time: string # The start date for when to get the pipeline and aggregate its data. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --end-date-time: string # The end date for when to get the pipeline and aggregate its data. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --api-version: string # Client Api Version.
]: nothing -> record<auHoursCanceled: float, auHoursFailed: float, auHoursSucceeded: float, lastSubmitTime: string, numJobsCanceled: int, numJobsFailed: int, numJobsSucceeded: int, pipelineId: string, pipelineName: string, pipelineUri: string, recurrences: list<string>, runs: table<lastSubmitTime: string, runId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pipeline_identity | is-empty) { error make --unspanned { msg: "path parameter 'pipelineIdentity' must be non-empty" } }
  let qp = [(serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pipeline_identity: (encode-path-segment $pipeline_identity)} | format pattern "/pipelines/{pipeline_identity}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDateTime": $start_date_time, "endDateTime": $end_date_time, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all recurrences.
#
# GET /recurrences
# operationId: Recurrence_List
export def "recurrences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date-time: string # The start date for when to get the list of recurrences. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --end-date-time: string # The end date for when to get the list of recurrences. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<auHoursCanceled: float, auHoursFailed: float, auHoursSucceeded: float, lastSubmitTime: string, numJobsCanceled: int, numJobsFailed: int, numJobsSucceeded: int, recurrenceId: string, recurrenceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recurrences" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDateTime": $start_date_time, "endDateTime": $end_date_time, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the recurrence information for the specified recurrence ID.
#
# GET /recurrences/{recurrenceIdentity}
# operationId: Recurrence_Get
export def "recurrences get" [
  recurrence_identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date-time: string # The start date for when to get the recurrence and aggregate its data. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --end-date-time: string # The end date for when to get recurrence and aggregate its data. The startDateTime and endDateTime can be no more than 30 days apart. (format: date-time)
  --api-version: string # Client Api Version.
]: nothing -> record<auHoursCanceled: float, auHoursFailed: float, auHoursSucceeded: float, lastSubmitTime: string, numJobsCanceled: int, numJobsFailed: int, numJobsSucceeded: int, recurrenceId: string, recurrenceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($recurrence_identity | is-empty) { error make --unspanned { msg: "path parameter 'recurrenceIdentity' must be non-empty" } }
  let qp = [(serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({recurrence_identity: (encode-path-segment $recurrence_identity)} | format pattern "/recurrences/{recurrence_identity}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startDateTime": $start_date_time, "endDateTime": $end_date_time, "api-version": $api_version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
