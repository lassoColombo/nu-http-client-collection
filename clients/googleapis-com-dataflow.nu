# Auto-generated client for Dataflow API vv1b3
# Source: https://api.apis.guru/v2/specs/googleapis.com/dataflow/v1b3/openapi.json
# Auth: --token flag or $env.DATAFLOW_API_TOKEN

const BASE_URL = "https://dataflow.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATAFLOW_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://dataflow.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def filter-completer [] { ["ACTIVE" "ALL" "TERMINATED" "UNKNOWN"] }
def view-completer [] { ["JOB_VIEW_ALL" "JOB_VIEW_DESCRIPTION" "JOB_VIEW_SUMMARY" "JOB_VIEW_UNKNOWN"] }
def current-state-completer [] { ["JOB_STATE_CANCELLED" "JOB_STATE_CANCELLING" "JOB_STATE_DONE" "JOB_STATE_DRAINED" "JOB_STATE_DRAINING" "JOB_STATE_FAILED" "JOB_STATE_PENDING" "JOB_STATE_QUEUED" "JOB_STATE_RESOURCE_CLEANING_UP" "JOB_STATE_RUNNING" "JOB_STATE_STOPPED" "JOB_STATE_UNKNOWN" "JOB_STATE_UPDATED"] }
def requested-state-completer [] { ["JOB_STATE_CANCELLED" "JOB_STATE_CANCELLING" "JOB_STATE_DONE" "JOB_STATE_DRAINED" "JOB_STATE_DRAINING" "JOB_STATE_FAILED" "JOB_STATE_PENDING" "JOB_STATE_QUEUED" "JOB_STATE_RESOURCE_CLEANING_UP" "JOB_STATE_RUNNING" "JOB_STATE_STOPPED" "JOB_STATE_UNKNOWN" "JOB_STATE_UPDATED"] }
def type-completer [] { ["JOB_TYPE_BATCH" "JOB_TYPE_STREAMING" "JOB_TYPE_UNKNOWN"] }
def data-format-completer [] { ["BROTLI" "DATA_FORMAT_UNSPECIFIED" "JSON" "RAW" "ZLIB"] }
def minimum-importance-completer [] { ["JOB_MESSAGE_BASIC" "JOB_MESSAGE_DEBUG" "JOB_MESSAGE_DETAILED" "JOB_MESSAGE_ERROR" "JOB_MESSAGE_IMPORTANCE_UNKNOWN" "JOB_MESSAGE_WARNING"] }
def view-completer-1 [] { ["METADATA_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1b3-projects-worker-messages create" } } | get name | first)
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

# Send a worker_message to the service.
#
# POST /v1b3/projects/{projectId}/WorkerMessages
# operationId: dataflow.projects.workerMessages
# --workerMessages item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
export def "v1b3-projects-worker-messages create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job.
  --worker-messages: list # The WorkerMessages to send. — item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
]: any -> record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/WorkerMessages") $qp)
  let req_body = {"location": $location, "workerMessages": $worker_messages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List the jobs of a project. To list the jobs of a project in a region, we recommend using `projects.locations.jobs.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). To list the all jobs across all regions, use `projects.jobs.aggregated`. Using `projects.jobs.list` is not recommended, as you can only get the list of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs
# operationId: dataflow.projects.jobs.list
export def "v1b3-projects-jobs list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --filter: string@filter-completer # The kind of filter to use.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # Optional. The job name. Optional.
  --page-size: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --page-token: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "location": $location, "name": $name, "pageSize": $page_size, "pageToken": $page_token, "view": $view} | compact), body: null}
}

# Creates a Cloud Dataflow job. To create a job, we recommend using `projects.locations.jobs.create` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.create` is not recommended, as your job will always start in `us-central1`. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/jobs
# operationId: dataflow.projects.jobs.create
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-jobs create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --replace-job-id: string # Deprecated. This field is now in the Job message.
  --view: string@view-completer # The level of information requested in response.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --location-body: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job. (body field)
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to.
  --replace-job-id-body: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job. (body field)
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "replaceJobId" $replace_job_id "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/jobs") $qp)
  let req_body = {"clientRequestId": $client_request_id, "createTime": $create_time, "createdFromSnapshotId": $created_from_snapshot_id, "currentState": $current_state, "currentStateTime": $current_state_time, "environment": $environment, "executionInfo": $execution_info, "id": $id, "jobMetadata": $job_metadata, "labels": $labels, "location": $location_body, "name": $name, "pipelineDescription": $pipeline_description, "projectId": $body_project_id, "replaceJobId": $replace_job_id_body, "replacedByJobId": $replaced_by_job_id, "requestedState": $requested_state, "satisfiesPzs": $satisfies_pzs, "stageStates": $stage_states, "startTime": $start_time, "steps": $steps, "stepsLocation": $steps_location, "tempFiles": $temp_files, "transformNameMapping": $transform_name_mapping, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "location": $location, "replaceJobId": $replace_job_id, "view": $view} | compact), body: $req_body}
}

# Gets the state of the specified Cloud Dataflow job. To get the state of a job, we recommend using `projects.locations.jobs.get` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.get` is not recommended, as you can only get the state of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}
# operationId: dataflow.projects.jobs.get
export def "v1b3-projects-jobs get" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --view: string@view-completer # The level of information requested in response.
]: nothing -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "location": $location, "view": $view} | compact), body: null}
}

# Updates the state of an existing Cloud Dataflow job. To update the state of an existing job, we recommend using `projects.locations.jobs.update` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.update` is not recommended, as you can only update the state of jobs that are running in `us-central1`.
#
# PUT /v1b3/projects/{projectId}/jobs/{jobId}
# operationId: dataflow.projects.jobs.update
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-jobs update" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --update-mask: string # The list of fields to update relative to Job. If empty, only RequestedJobState will be considered for update. If the FieldMask is not empty and RequestedJobState is none/empty, The fields specified in the update mask will be the only ones considered for update. If both RequestedJobState and update_mask are specified, we will first handle RequestedJobState and then the update_mask fields.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --location-body: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job. (body field)
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to.
  --replace-job-id: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}") $qp)
  let req_body = {"clientRequestId": $client_request_id, "createTime": $create_time, "createdFromSnapshotId": $created_from_snapshot_id, "currentState": $current_state, "currentStateTime": $current_state_time, "environment": $environment, "executionInfo": $execution_info, "id": $id, "jobMetadata": $job_metadata, "labels": $labels, "location": $location_body, "name": $name, "pipelineDescription": $pipeline_description, "projectId": $body_project_id, "replaceJobId": $replace_job_id, "replacedByJobId": $replaced_by_job_id, "requestedState": $requested_state, "satisfiesPzs": $satisfies_pzs, "stageStates": $stage_states, "startTime": $start_time, "steps": $steps, "stepsLocation": $steps_location, "tempFiles": $temp_files, "transformNameMapping": $transform_name_mapping, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "location": $location, "updateMask": $update_mask} | compact), body: $req_body}
}

# Get encoded debug configuration for component. Not cacheable.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/debug/getConfig
# operationId: dataflow.projects.jobs.debug.getConfig
export def "v1b3-projects-jobs-debug-get-config get" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --component-id: string # The internal component id for which debug configuration is requested.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> record<config: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}/debug/getConfig") $qp)
  let req_body = {"componentId": $component_id, "location": $location, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Send encoded debug capture data for component.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/debug/sendCapture
# operationId: dataflow.projects.jobs.debug.sendCapture
export def "v1b3-projects-jobs-debug-send-capture send" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --component-id: string # The internal component id for which debug information is sent.
  --data: string # The encoded debug information.
  --data-format: string@data-format-completer # Format for the data field above (id=5).
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}/debug/sendCapture") $qp)
  let req_body = {"componentId": $component_id, "data": $data, "dataFormat": $data_format, "location": $location, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.messages.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.messages.list` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}/messages
# operationId: dataflow.projects.jobs.messages.list
export def "v1b3-projects-jobs-messages list" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --end-time: string # Return only messages with timestamps < end_time. The default is now (i.e. return up to the latest messages available).
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --minimum-importance: string@minimum-importance-completer # Filter to only get messages with importance >= level
  --page-size: int # If specified, determines the maximum number of messages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --start-time: string # If specified, return only messages with timestamps >= start_time. The default is the job creation time (i.e. beginning of messages).
]: nothing -> record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "minimumImportance" $minimum_importance "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "startTime" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}/messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "endTime": $end_time, "location": $location, "minimumImportance": $minimum_importance, "pageSize": $page_size, "pageToken": $page_token, "startTime": $start_time} | compact), body: null}
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.getMetrics` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.getMetrics` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}/metrics
# operationId: dataflow.projects.jobs.getMetrics
export def "v1b3-projects-jobs-metrics get" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --start-time: string # Return only metric data that has changed since this time. Default is to return all information about all metrics for the job.
]: nothing -> record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "startTime" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}/metrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "location": $location, "startTime": $start_time} | compact), body: null}
}

# Leases a dataflow WorkItem to run.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/workItems:lease
# operationId: dataflow.projects.jobs.workItems.lease
export def "v1b3-projects-jobs-work-items-lease create" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --requested-lease-duration: string # The initial lease period. (format: google-duration)
  --unified-worker-request: record # Untranslated bag-of-bytes WorkRequest from UnifiedWorker.
  --work-item-types: list<string> # Filter for WorkItem type.
  --worker-capabilities: list<string> # Worker capabilities. WorkItems might be limited to workers with specific capabilities.
  --worker-id: string # Identifies the worker leasing work -- typically the ID of the virtual machine running the worker.
]: any -> record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}/workItems:lease") $qp)
  let req_body = {"currentWorkerTime": $current_worker_time, "location": $location, "requestedLeaseDuration": $requested_lease_duration, "unifiedWorkerRequest": $unified_worker_request, "workItemTypes": $work_item_types, "workerCapabilities": $worker_capabilities, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Reports the status of dataflow WorkItems leased by a worker.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/workItems:reportStatus
# operationId: dataflow.projects.jobs.workItems.reportStatus
# --workItemStatuses item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
export def "v1b3-projects-jobs-work-items-report-status create" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --unified-worker-request: record # Untranslated bag-of-bytes WorkProgressUpdateRequest from UnifiedWorker.
  --work-item-statuses: list # The order is unimportant, except that the order of the WorkItemServiceState messages in the ReportWorkItemStatusResponse corresponds to the order of WorkItemStatus messages here. — item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
  --worker-id: string # The ID of the worker reporting the WorkItem status. If this does not match the ID of the worker which the Dataflow service believes currently has the lease on the WorkItem, the report will be dropped (with an error response).
]: any -> record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}/workItems:reportStatus") $qp)
  let req_body = {"currentWorkerTime": $current_worker_time, "location": $location, "unifiedWorkerRequest": $unified_worker_request, "workItemStatuses": $work_item_statuses, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Snapshot the state of a streaming job.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}:snapshot
# operationId: dataflow.projects.jobs.snapshot
export def "v1b3-projects-jobs create-snapshot" [
  project_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --description: string # User specified description of the snapshot. Maybe empty.
  --location: string # The location that contains this job.
  --snapshot-sources: oneof<nothing, bool> # If true, perform snapshots for sources which support this.
  --ttl: string # TTL for the snapshot. (format: google-duration)
]: any -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/jobs/{job_id}:snapshot") $qp)
  let req_body = {"description": $description, "location": $location, "snapshotSources": $snapshot_sources, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List the jobs of a project across all regions.
#
# GET /v1b3/projects/{projectId}/jobs:aggregated
# operationId: dataflow.projects.jobs.aggregated
export def "v1b3-projects-jobs-aggregated get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --filter: string@filter-completer # The kind of filter to use.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # Optional. The job name. Optional.
  --page-size: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --page-token: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/jobs:aggregated") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "location": $location, "name": $name, "pageSize": $page_size, "pageToken": $page_token, "view": $view} | compact), body: null}
}

# Send a worker_message to the service.
#
# POST /v1b3/projects/{projectId}/locations/{location}/WorkerMessages
# operationId: dataflow.projects.locations.workerMessages
# --workerMessages item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
export def "v1b3-projects-locations-worker-messages create" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job.
  --worker-messages: list # The WorkerMessages to send. — item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
]: any -> record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/WorkerMessages") $qp)
  let req_body = {"location": $body_location, "workerMessages": $worker_messages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Launch a job with a FlexTemplate.
#
# POST /v1b3/projects/{projectId}/locations/{location}/flexTemplates:launch
# operationId: dataflow.projects.locations.flexTemplates.launch
# --launchParameter shape: {containerSpec?: record, containerSpecGcsPath?: string, environment?: record, jobName?: string, launchOptions?: record, parameters?: record, transformNameMappings?: record, update?: bool}
export def "v1b3-projects-locations-flex-templates-launch create" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --launch-parameter: record # Launch FlexTemplate Parameter. — shape: {containerSpec?: record, containerSpecGcsPath?: string, environment?: record, jobName?: string, launchOptions?: record, parameters?: record, transformNameMappings?: record, update?: bool}
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
]: any -> record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/flexTemplates:launch") $qp)
  let req_body = {"launchParameter": $launch_parameter, "validateOnly": $validate_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# List the jobs of a project. To list the jobs of a project in a region, we recommend using `projects.locations.jobs.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). To list the all jobs across all regions, use `projects.jobs.aggregated`. Using `projects.jobs.list` is not recommended, as you can only get the list of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs
# operationId: dataflow.projects.locations.jobs.list
export def "v1b3-projects-locations-jobs list" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --filter: string@filter-completer # The kind of filter to use.
  --name: string # Optional. The job name. Optional.
  --page-size: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --page-token: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "filter": $filter, "name": $name, "pageSize": $page_size, "pageToken": $page_token, "view": $view} | compact), body: null}
}

# Creates a Cloud Dataflow job. To create a job, we recommend using `projects.locations.jobs.create` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.create` is not recommended, as your job will always start in `us-central1`. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs
# operationId: dataflow.projects.locations.jobs.create
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-locations-jobs create" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --replace-job-id: string # Deprecated. This field is now in the Job message.
  --view: string@view-completer # The level of information requested in response.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to.
  --replace-job-id-body: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job. (body field)
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "replaceJobId" $replace_job_id "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs") $qp)
  let req_body = {"clientRequestId": $client_request_id, "createTime": $create_time, "createdFromSnapshotId": $created_from_snapshot_id, "currentState": $current_state, "currentStateTime": $current_state_time, "environment": $environment, "executionInfo": $execution_info, "id": $id, "jobMetadata": $job_metadata, "labels": $labels, "location": $body_location, "name": $name, "pipelineDescription": $pipeline_description, "projectId": $body_project_id, "replaceJobId": $replace_job_id_body, "replacedByJobId": $replaced_by_job_id, "requestedState": $requested_state, "satisfiesPzs": $satisfies_pzs, "stageStates": $stage_states, "startTime": $start_time, "steps": $steps, "stepsLocation": $steps_location, "tempFiles": $temp_files, "transformNameMapping": $transform_name_mapping, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "replaceJobId": $replace_job_id, "view": $view} | compact), body: $req_body}
}

# Gets the state of the specified Cloud Dataflow job. To get the state of a job, we recommend using `projects.locations.jobs.get` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.get` is not recommended, as you can only get the state of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}
# operationId: dataflow.projects.locations.jobs.get
export def "v1b3-projects-locations-jobs get" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --view: string@view-completer # The level of information requested in response.
]: nothing -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "view": $view} | compact), body: null}
}

# Updates the state of an existing Cloud Dataflow job. To update the state of an existing job, we recommend using `projects.locations.jobs.update` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.update` is not recommended, as you can only update the state of jobs that are running in `us-central1`.
#
# PUT /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}
# operationId: dataflow.projects.locations.jobs.update
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-locations-jobs update" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --update-mask: string # The list of fields to update relative to Job. If empty, only RequestedJobState will be considered for update. If the FieldMask is not empty and RequestedJobState is none/empty, The fields specified in the update mask will be the only ones considered for update. If both RequestedJobState and update_mask are specified, we will first handle RequestedJobState and then the update_mask fields.
  --client-request-id: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --create-time: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --created-from-snapshot-id: string # If this is specified, the job's initial state is populated from the given snapshot.
  --current-state: string@current-state-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --current-state-time: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list<string>, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list<string>, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --execution-info: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --job-metadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipeline-description: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-project-id: string # The ID of the Cloud Platform project that the job belongs to.
  --replace-job-id: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replaced-by-job-id: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requested-state: string@requested-state-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfies-pzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stage-states: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --start-time: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --steps-location: string # The Cloud Storage location where the steps are stored.
  --temp-files: list<string> # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transform-name-mapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}") $qp)
  let req_body = {"clientRequestId": $client_request_id, "createTime": $create_time, "createdFromSnapshotId": $created_from_snapshot_id, "currentState": $current_state, "currentStateTime": $current_state_time, "environment": $environment, "executionInfo": $execution_info, "id": $id, "jobMetadata": $job_metadata, "labels": $labels, "location": $body_location, "name": $name, "pipelineDescription": $pipeline_description, "projectId": $body_project_id, "replaceJobId": $replace_job_id, "replacedByJobId": $replaced_by_job_id, "requestedState": $requested_state, "satisfiesPzs": $satisfies_pzs, "stageStates": $stage_states, "startTime": $start_time, "steps": $steps, "stepsLocation": $steps_location, "tempFiles": $temp_files, "transformNameMapping": $transform_name_mapping, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "updateMask": $update_mask} | compact), body: $req_body}
}

# Get encoded debug configuration for component. Not cacheable.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/getConfig
# operationId: dataflow.projects.locations.jobs.debug.getConfig
export def "v1b3-projects-locations-jobs-debug-get-config get" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --component-id: string # The internal component id for which debug configuration is requested.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> record<config: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/debug/getConfig") $qp)
  let req_body = {"componentId": $component_id, "location": $body_location, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Send encoded debug capture data for component.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/sendCapture
# operationId: dataflow.projects.locations.jobs.debug.sendCapture
export def "v1b3-projects-locations-jobs-debug-send-capture send" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --component-id: string # The internal component id for which debug information is sent.
  --data: string # The encoded debug information.
  --data-format: string@data-format-completer # Format for the data field above (id=5).
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --worker-id: string # The worker id, i.e., VM hostname.
]: any -> record {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/debug/sendCapture") $qp)
  let req_body = {"componentId": $component_id, "data": $data, "dataFormat": $data_format, "location": $body_location, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Request detailed information about the execution status of the job. EXPERIMENTAL. This API is subject to change or removal without notice.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/executionDetails
# operationId: dataflow.projects.locations.jobs.getExecutionDetails
export def "v1b3-projects-locations-jobs-execution-details get" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --page-size: int # If specified, determines the maximum number of stages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
]: nothing -> record<nextPageToken: string, stages: table<endTime: string, metrics: list, progress: record, stageId: string, startTime: string, state: string, stragglerSummary: record>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/executionDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.messages.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.messages.list` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/messages
# operationId: dataflow.projects.locations.jobs.messages.list
export def "v1b3-projects-locations-jobs-messages list" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --end-time: string # Return only messages with timestamps < end_time. The default is now (i.e. return up to the latest messages available).
  --minimum-importance: string@minimum-importance-completer # Filter to only get messages with importance >= level
  --page-size: int # If specified, determines the maximum number of messages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --start-time: string # If specified, return only messages with timestamps >= start_time. The default is the job creation time (i.e. beginning of messages).
]: nothing -> record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "minimumImportance" $minimum_importance "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "startTime" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "endTime": $end_time, "minimumImportance": $minimum_importance, "pageSize": $page_size, "pageToken": $page_token, "startTime": $start_time} | compact), body: null}
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.getMetrics` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.getMetrics` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/metrics
# operationId: dataflow.projects.locations.jobs.getMetrics
export def "v1b3-projects-locations-jobs-metrics get" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --start-time: string # Return only metric data that has changed since this time. Default is to return all information about all metrics for the job.
]: nothing -> record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "startTime" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/metrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "startTime": $start_time} | compact), body: null}
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/snapshots
# operationId: dataflow.projects.locations.jobs.snapshots.list
export def "v1b3-projects-locations-jobs-snapshots list" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/snapshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Request detailed information about the execution status of a stage of the job. EXPERIMENTAL. This API is subject to change or removal without notice.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/stages/{stageId}/executionDetails
# operationId: dataflow.projects.locations.jobs.stages.getExecutionDetails
export def "v1b3-projects-locations-jobs-stages-execution-details get" [
  project_id: string
  location: string
  job_id: string
  stage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --end-time: string # Upper time bound of work items to include, by start time.
  --page-size: int # If specified, determines the maximum number of work items to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --page-token: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --start-time: string # Lower time bound of work items to include, by start time.
]: nothing -> record<nextPageToken: string, workers: table<workItems: list, workerName: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($stage_id | is-empty) { error make --unspanned { msg: "path parameter 'stageId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "startTime" $start_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id), stage_id: (encode-path-segment $stage_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/stages/{stage_id}/executionDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "endTime": $end_time, "pageSize": $page_size, "pageToken": $page_token, "startTime": $start_time} | compact), body: null}
}

# Leases a dataflow WorkItem to run.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:lease
# operationId: dataflow.projects.locations.jobs.workItems.lease
export def "v1b3-projects-locations-jobs-work-items-lease create" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --requested-lease-duration: string # The initial lease period. (format: google-duration)
  --unified-worker-request: record # Untranslated bag-of-bytes WorkRequest from UnifiedWorker.
  --work-item-types: list<string> # Filter for WorkItem type.
  --worker-capabilities: list<string> # Worker capabilities. WorkItems might be limited to workers with specific capabilities.
  --worker-id: string # Identifies the worker leasing work -- typically the ID of the virtual machine running the worker.
]: any -> record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/workItems:lease") $qp)
  let req_body = {"currentWorkerTime": $current_worker_time, "location": $body_location, "requestedLeaseDuration": $requested_lease_duration, "unifiedWorkerRequest": $unified_worker_request, "workItemTypes": $work_item_types, "workerCapabilities": $worker_capabilities, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Reports the status of dataflow WorkItems leased by a worker.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:reportStatus
# operationId: dataflow.projects.locations.jobs.workItems.reportStatus
# --workItemStatuses item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
export def "v1b3-projects-locations-jobs-work-items-report-status create" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --current-worker-time: string # The current timestamp at the worker. (format: google-datetime)
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --unified-worker-request: record # Untranslated bag-of-bytes WorkProgressUpdateRequest from UnifiedWorker.
  --work-item-statuses: list # The order is unimportant, except that the order of the WorkItemServiceState messages in the ReportWorkItemStatusResponse corresponds to the order of WorkItemStatus messages here. — item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
  --worker-id: string # The ID of the worker reporting the WorkItem status. If this does not match the ID of the worker which the Dataflow service believes currently has the lease on the WorkItem, the report will be dropped (with an error response).
]: any -> record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}/workItems:reportStatus") $qp)
  let req_body = {"currentWorkerTime": $current_worker_time, "location": $body_location, "unifiedWorkerRequest": $unified_worker_request, "workItemStatuses": $work_item_statuses, "workerId": $worker_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Snapshot the state of a streaming job.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}:snapshot
# operationId: dataflow.projects.locations.jobs.snapshot
export def "v1b3-projects-locations-jobs create-snapshot" [
  project_id: string
  location: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --description: string # User specified description of the snapshot. Maybe empty.
  --body-location: string # The location that contains this job.
  --snapshot-sources: oneof<nothing, bool> # If true, perform snapshots for sources which support this.
  --ttl: string # TTL for the snapshot. (format: google-duration)
]: any -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), job_id: (encode-path-segment $job_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/jobs/{job_id}:snapshot") $qp)
  let req_body = {"description": $description, "location": $body_location, "snapshotSources": $snapshot_sources, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/locations/{location}/snapshots
# operationId: dataflow.projects.locations.snapshots.list
export def "v1b3-projects-locations-snapshots list" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --job-id: string # If specified, list snapshots created from this job.
]: nothing -> record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "jobId" $job_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/snapshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "jobId": $job_id} | compact), body: null}
}

# Deletes a snapshot.
#
# DELETE /v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}
# operationId: dataflow.projects.locations.snapshots.delete
export def "v1b3-projects-locations-snapshots delete" [
  project_id: string
  location: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/snapshots/{snapshot_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets information about a snapshot.
#
# GET /v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}
# operationId: dataflow.projects.locations.snapshots.get
export def "v1b3-projects-locations-snapshots get" [
  project_id: string
  location: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
]: nothing -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/snapshots/{snapshot_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Creates a Cloud Dataflow job from a template. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/locations/{location}/templates
# operationId: dataflow.projects.locations.templates.create
# --environment shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-locations-templates create" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --job-name: string # Required. The job name to use for the created job.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --parameters: record # The runtime parameters to pass to the job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/templates") $qp)
  let req_body = {"environment": $environment, "gcsPath": $gcs_path, "jobName": $job_name, "location": $body_location, "parameters": $parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Get the template associated with a template.
#
# GET /v1b3/projects/{projectId}/locations/{location}/templates:get
# operationId: dataflow.projects.locations.templates.get
export def "v1b3-projects-locations-templates-get get" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --view: string@view-completer-1 # The view to retrieve. Defaults to METADATA_ONLY.
]: nothing -> record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "gcsPath" $gcs_path "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/templates:get") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "gcsPath": $gcs_path, "view": $view} | compact), body: null}
}

# Launch a template.
#
# POST /v1b3/projects/{projectId}/locations/{location}/templates:launch
# operationId: dataflow.projects.locations.templates.launch
# --environment shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-locations-templates-launch create" [
  project_id: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --dynamic-template-gcs-path: string # Path to dynamic template spec file on Cloud Storage. The file must be a Json serialized DynamicTemplateFieSpec object.
  --dynamic-template-staging-location: string # Cloud Storage path for staging dependencies. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --gcs-path: string # A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --job-name: string # Required. The job name to use for the created job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --parameters: record # The runtime parameters to pass to the job.
  --transform-name-mapping: record # Only applicable when updating a pipeline. Map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --update: oneof<nothing, bool> # If set, replace the existing pipeline with the name specified by jobName with this pipeline, preserving state.
]: any -> record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dynamicTemplate.gcsPath" $dynamic_template_gcs_path "scalar") (serialize-qp "dynamicTemplate.stagingLocation" $dynamic_template_staging_location "scalar") (serialize-qp "gcsPath" $gcs_path "scalar") (serialize-qp "validateOnly" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), location: (encode-path-segment $location)} | format pattern "/v1b3/projects/{project_id}/locations/{location}/templates:launch") $qp)
  let req_body = {"environment": $environment, "jobName": $job_name, "parameters": $parameters, "transformNameMapping": $transform_name_mapping, "update": $update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "dynamicTemplate.gcsPath": $dynamic_template_gcs_path, "dynamicTemplate.stagingLocation": $dynamic_template_staging_location, "gcsPath": $gcs_path, "validateOnly": $validate_only} | compact), body: $req_body}
}

# Deletes a snapshot.
#
# DELETE /v1b3/projects/{projectId}/snapshots
# operationId: dataflow.projects.deleteSnapshots
export def "v1b3-projects-snapshots delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --location: string # The location that contains this snapshot.
  --snapshot-id: string # The ID of the snapshot.
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "snapshotId" $snapshot_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/snapshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "location": $location, "snapshotId": $snapshot_id} | compact), body: null}
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/snapshots
# operationId: dataflow.projects.snapshots.list
export def "v1b3-projects-snapshots list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --job-id: string # If specified, list snapshots created from this job.
  --location: string # The location to list snapshots in.
]: nothing -> record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "jobId" $job_id "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/snapshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "jobId": $job_id, "location": $location} | compact), body: null}
}

# Gets information about a snapshot.
#
# GET /v1b3/projects/{projectId}/snapshots/{snapshotId}
# operationId: dataflow.projects.snapshots.get
export def "v1b3-projects-snapshots get" [
  project_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --location: string # The location that contains this snapshot.
]: nothing -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v1b3/projects/{project_id}/snapshots/{snapshot_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "location": $location} | compact), body: null}
}

# Creates a Cloud Dataflow job from a template. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/templates
# operationId: dataflow.projects.templates.create
# --environment shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-templates create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --job-name: string # Required. The job name to use for the created job.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --parameters: record # The runtime parameters to pass to the job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/templates") $qp)
  let req_body = {"environment": $environment, "gcsPath": $gcs_path, "jobName": $job_name, "location": $location, "parameters": $parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Get the template associated with a template.
#
# GET /v1b3/projects/{projectId}/templates:get
# operationId: dataflow.projects.templates.get
export def "v1b3-projects-templates-get get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --gcs-path: string # Required. A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --view: string@view-completer-1 # The view to retrieve. Defaults to METADATA_ONLY.
]: nothing -> record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string> {
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "gcsPath" $gcs_path "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/templates:get") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "gcsPath": $gcs_path, "location": $location, "view": $view} | compact), body: null}
}

# Launch a template.
#
# POST /v1b3/projects/{projectId}/templates:launch
# operationId: dataflow.projects.templates.launch
# --environment shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-templates-launch create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-oauth2: string # Auth token for Oauth2 (Authorization)
  --token-oauth2c: string # Auth token for Oauth2c (Authorization)
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
  --dynamic-template-gcs-path: string # Path to dynamic template spec file on Cloud Storage. The file must be a Json serialized DynamicTemplateFieSpec object.
  --dynamic-template-staging-location: string # Cloud Storage path for staging dependencies. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --gcs-path: string # A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list<string>, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --job-name: string # Required. The job name to use for the created job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --parameters: record # The runtime parameters to pass to the job.
  --transform-name-mapping: record # Only applicable when updating a pipeline. Map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --update: oneof<nothing, bool> # If set, replace the existing pipeline with the name specified by jobName with this pipeline, preserving state.
]: any -> record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_oauth2 | default ($env | get -o DATAFLOW_API_OAUTH2_TOKEN | default "")) "bearer") (build-auth ($token_oauth2c | default ($env | get -o DATAFLOW_API_OAUTH2C_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dynamicTemplate.gcsPath" $dynamic_template_gcs_path "scalar") (serialize-qp "dynamicTemplate.stagingLocation" $dynamic_template_staging_location "scalar") (serialize-qp "gcsPath" $gcs_path "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "validateOnly" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1b3/projects/{project_id}/templates:launch") $qp)
  let req_body = {"environment": $environment, "jobName": $job_name, "parameters": $parameters, "transformNameMapping": $transform_name_mapping, "update": $update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "dynamicTemplate.gcsPath": $dynamic_template_gcs_path, "dynamicTemplate.stagingLocation": $dynamic_template_staging_location, "gcsPath": $gcs_path, "location": $location, "validateOnly": $validate_only} | compact), body: $req_body}
}
