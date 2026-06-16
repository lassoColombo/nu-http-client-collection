# Auto-generated client for Dataflow API vv1b3
# Source: https://api.apis.guru/v2/specs/googleapis.com/dataflow/v1b3/openapi.json
# Auth: --token flag or $env.DATAFLOW_API_TOKEN

const BASE_URL = "https://dataflow.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATAFLOW_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://dataflow.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def filter-completer [] { ["ACTIVE" "ALL" "TERMINATED" "UNKNOWN"] }
def view-completer [] { ["JOB_VIEW_ALL" "JOB_VIEW_DESCRIPTION" "JOB_VIEW_SUMMARY" "JOB_VIEW_UNKNOWN"] }
def currentState-completer [] { ["JOB_STATE_CANCELLED" "JOB_STATE_CANCELLING" "JOB_STATE_DONE" "JOB_STATE_DRAINED" "JOB_STATE_DRAINING" "JOB_STATE_FAILED" "JOB_STATE_PENDING" "JOB_STATE_QUEUED" "JOB_STATE_RESOURCE_CLEANING_UP" "JOB_STATE_RUNNING" "JOB_STATE_STOPPED" "JOB_STATE_UNKNOWN" "JOB_STATE_UPDATED"] }
def requestedState-completer [] { ["JOB_STATE_CANCELLED" "JOB_STATE_CANCELLING" "JOB_STATE_DONE" "JOB_STATE_DRAINED" "JOB_STATE_DRAINING" "JOB_STATE_FAILED" "JOB_STATE_PENDING" "JOB_STATE_QUEUED" "JOB_STATE_RESOURCE_CLEANING_UP" "JOB_STATE_RUNNING" "JOB_STATE_STOPPED" "JOB_STATE_UNKNOWN" "JOB_STATE_UPDATED"] }
def type-completer [] { ["JOB_TYPE_BATCH" "JOB_TYPE_STREAMING" "JOB_TYPE_UNKNOWN"] }
def dataFormat-completer [] { ["BROTLI" "DATA_FORMAT_UNSPECIFIED" "JSON" "RAW" "ZLIB"] }
def minimumImportance-completer [] { ["JOB_MESSAGE_BASIC" "JOB_MESSAGE_DEBUG" "JOB_MESSAGE_DETAILED" "JOB_MESSAGE_ERROR" "JOB_MESSAGE_IMPORTANCE_UNKNOWN" "JOB_MESSAGE_WARNING"] }
def view-completer-1 [] { ["METADATA_ONLY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1b3-projects-worker-messages dataflowprojectsworkerMessages" } } | get name | first)
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
export def "v1b3-projects-worker-messages dataflowprojectsworkerMessages" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job.
  --workerMessages: list # The WorkerMessages to send. — item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
]: any -> record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/WorkerMessages" $qp)
  let body = {location: $location, workerMessages: $workerMessages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the jobs of a project. To list the jobs of a project in a region, we recommend using `projects.locations.jobs.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). To list the all jobs across all regions, use `projects.jobs.aggregated`. Using `projects.jobs.list` is not recommended, as you can only get the list of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs
# operationId: dataflow.projects.jobs.list
export def "v1b3-projects-jobs dataflowprojectsjobslist" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string@filter-completer # The kind of filter to use.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # Optional. The job name. Optional.
  --pageSize: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --pageToken: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Cloud Dataflow job. To create a job, we recommend using `projects.locations.jobs.create` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.create` is not recommended, as your job will always start in `us-central1`. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/jobs
# operationId: dataflow.projects.jobs.create
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-jobs dataflowprojectsjobscreate" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --replaceJobId: string # Deprecated. This field is now in the Job message.
  --view: string@view-completer # The level of information requested in response.
  --clientRequestId: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --createTime: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --createdFromSnapshotId: string # If this is specified, the job's initial state is populated from the given snapshot.
  --currentState: string@currentState-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --currentStateTime: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --executionInfo: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --jobMetadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipelineDescription: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-projectId: string # The ID of the Cloud Platform project that the job belongs to.
  --replaceJobId: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replacedByJobId: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requestedState: string@requestedState-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfiesPzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stageStates: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --startTime: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --stepsLocation: string # The Cloud Storage location where the steps are stored.
  --tempFiles: list # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transformNameMapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "replaceJobId" $replaceJobId "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs" $qp)
  let body = {clientRequestId: $clientRequestId, createTime: $createTime, createdFromSnapshotId: $createdFromSnapshotId, currentState: $currentState, currentStateTime: $currentStateTime, environment: $environment, executionInfo: $executionInfo, id: $id, jobMetadata: $jobMetadata, labels: $labels, location: $location, name: $name, pipelineDescription: $pipelineDescription, projectId: $body_projectId, replaceJobId: $replaceJobId, replacedByJobId: $replacedByJobId, requestedState: $requestedState, satisfiesPzs: $satisfiesPzs, stageStates: $stageStates, startTime: $startTime, steps: $steps, stepsLocation: $stepsLocation, tempFiles: $tempFiles, transformNameMapping: $transformNameMapping, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the state of the specified Cloud Dataflow job. To get the state of a job, we recommend using `projects.locations.jobs.get` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.get` is not recommended, as you can only get the state of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}
# operationId: dataflow.projects.jobs.get
export def "v1b3-projects-jobs dataflowprojectsjobsget" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --view: string@view-completer # The level of information requested in response.
]: nothing -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the state of an existing Cloud Dataflow job. To update the state of an existing job, we recommend using `projects.locations.jobs.update` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.update` is not recommended, as you can only update the state of jobs that are running in `us-central1`.
#
# PUT /v1b3/projects/{projectId}/jobs/{jobId}
# operationId: dataflow.projects.jobs.update
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-jobs dataflowprojectsjobsupdate" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --updateMask: string # The list of fields to update relative to Job. If empty, only RequestedJobState will be considered for update. If the FieldMask is not empty and RequestedJobState is none/empty, The fields specified in the update mask will be the only ones considered for update. If both RequestedJobState and update_mask are specified, we will first handle RequestedJobState and then the update_mask fields.
  --clientRequestId: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --createTime: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --createdFromSnapshotId: string # If this is specified, the job's initial state is populated from the given snapshot.
  --currentState: string@currentState-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --currentStateTime: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --executionInfo: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --jobMetadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipelineDescription: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-projectId: string # The ID of the Cloud Platform project that the job belongs to.
  --replaceJobId: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replacedByJobId: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requestedState: string@requestedState-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfiesPzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stageStates: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --startTime: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --stepsLocation: string # The Cloud Storage location where the steps are stored.
  --tempFiles: list # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transformNameMapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)" $qp)
  let body = {clientRequestId: $clientRequestId, createTime: $createTime, createdFromSnapshotId: $createdFromSnapshotId, currentState: $currentState, currentStateTime: $currentStateTime, environment: $environment, executionInfo: $executionInfo, id: $id, jobMetadata: $jobMetadata, labels: $labels, location: $location, name: $name, pipelineDescription: $pipelineDescription, projectId: $body_projectId, replaceJobId: $replaceJobId, replacedByJobId: $replacedByJobId, requestedState: $requestedState, satisfiesPzs: $satisfiesPzs, stageStates: $stageStates, startTime: $startTime, steps: $steps, stepsLocation: $stepsLocation, tempFiles: $tempFiles, transformNameMapping: $transformNameMapping, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get encoded debug configuration for component. Not cacheable.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/debug/getConfig
# operationId: dataflow.projects.jobs.debug.getConfig
export def "v1b3-projects-jobs-debug-get-config dataflowprojectsjobsdebuggetConfig" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --componentId: string # The internal component id for which debug configuration is requested.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --workerId: string # The worker id, i.e., VM hostname.
]: any -> record<config: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)/debug/getConfig" $qp)
  let body = {componentId: $componentId, location: $location, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send encoded debug capture data for component.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/debug/sendCapture
# operationId: dataflow.projects.jobs.debug.sendCapture
export def "v1b3-projects-jobs-debug-send-capture dataflowprojectsjobsdebugsendCapture" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --componentId: string # The internal component id for which debug information is sent.
  --data: string # The encoded debug information.
  --dataFormat: string@dataFormat-completer # Format for the data field above (id=5).
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --workerId: string # The worker id, i.e., VM hostname.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)/debug/sendCapture" $qp)
  let body = {componentId: $componentId, data: $data, dataFormat: $dataFormat, location: $location, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.messages.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.messages.list` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}/messages
# operationId: dataflow.projects.jobs.messages.list
export def "v1b3-projects-jobs-messages dataflowprojectsjobsmessageslist" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --endTime: string # Return only messages with timestamps < end_time. The default is now (i.e. return up to the latest messages available).
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --minimumImportance: string@minimumImportance-completer # Filter to only get messages with importance >= level
  --pageSize: int # If specified, determines the maximum number of messages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --pageToken: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --startTime: string # If specified, return only messages with timestamps >= start_time. The default is the job creation time (i.e. beginning of messages).
]: nothing -> record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "minimumImportance" $minimumImportance "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.getMetrics` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.getMetrics` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/jobs/{jobId}/metrics
# operationId: dataflow.projects.jobs.getMetrics
export def "v1b3-projects-jobs-metrics dataflowprojectsjobsgetMetrics" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --startTime: string # Return only metric data that has changed since this time. Default is to return all information about all metrics for the job.
]: nothing -> record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Leases a dataflow WorkItem to run.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/workItems:lease
# operationId: dataflow.projects.jobs.workItems.lease
export def "v1b3-projects-jobs-work-items-lease dataflowprojectsjobsworkItemslease" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --currentWorkerTime: string # The current timestamp at the worker. (format: google-datetime)
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --requestedLeaseDuration: string # The initial lease period. (format: google-duration)
  --unifiedWorkerRequest: record # Untranslated bag-of-bytes WorkRequest from UnifiedWorker.
  --workItemTypes: list # Filter for WorkItem type.
  --workerCapabilities: list # Worker capabilities. WorkItems might be limited to workers with specific capabilities.
  --workerId: string # Identifies the worker leasing work -- typically the ID of the virtual machine running the worker.
]: any -> record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)/workItems:lease" $qp)
  let body = {currentWorkerTime: $currentWorkerTime, location: $location, requestedLeaseDuration: $requestedLeaseDuration, unifiedWorkerRequest: $unifiedWorkerRequest, workItemTypes: $workItemTypes, workerCapabilities: $workerCapabilities, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reports the status of dataflow WorkItems leased by a worker.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}/workItems:reportStatus
# operationId: dataflow.projects.jobs.workItems.reportStatus
# --workItemStatuses item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
export def "v1b3-projects-jobs-work-items-report-status dataflowprojectsjobsworkItemsreportStatus" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --currentWorkerTime: string # The current timestamp at the worker. (format: google-datetime)
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --unifiedWorkerRequest: record # Untranslated bag-of-bytes WorkProgressUpdateRequest from UnifiedWorker.
  --workItemStatuses: list # The order is unimportant, except that the order of the WorkItemServiceState messages in the ReportWorkItemStatusResponse corresponds to the order of WorkItemStatus messages here. — item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
  --workerId: string # The ID of the worker reporting the WorkItem status. If this does not match the ID of the worker which the Dataflow service believes currently has the lease on the WorkItem, the report will be dropped (with an error response).
]: any -> record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId)/workItems:reportStatus" $qp)
  let body = {currentWorkerTime: $currentWorkerTime, location: $location, unifiedWorkerRequest: $unifiedWorkerRequest, workItemStatuses: $workItemStatuses, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Snapshot the state of a streaming job.
#
# POST /v1b3/projects/{projectId}/jobs/{jobId}:snapshot
# operationId: dataflow.projects.jobs.snapshot
export def "v1b3-projects-jobs dataflowprojectsjobssnapshot" [
  projectId: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --description: string # User specified description of the snapshot. Maybe empty.
  --location: string # The location that contains this job.
  --snapshotSources: oneof<nothing, bool> # If true, perform snapshots for sources which support this.
  --ttl: string # TTL for the snapshot. (format: google-duration)
]: any -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs/($jobId):snapshot" $qp)
  let body = {description: $description, location: $location, snapshotSources: $snapshotSources, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the jobs of a project across all regions.
#
# GET /v1b3/projects/{projectId}/jobs:aggregated
# operationId: dataflow.projects.jobs.aggregated
export def "v1b3-projects-jobs-aggregated dataflowprojectsjobsaggregated" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string@filter-completer # The kind of filter to use.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # Optional. The job name. Optional.
  --pageSize: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --pageToken: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/jobs:aggregated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a worker_message to the service.
#
# POST /v1b3/projects/{projectId}/locations/{location}/WorkerMessages
# operationId: dataflow.projects.locations.workerMessages
# --workerMessages item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
export def "v1b3-projects-locations-worker-messages dataflowprojectslocationsworkerMessages" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job.
  --workerMessages: list # The WorkerMessages to send. — item shape: {labels?: record, time?: string, workerHealthReport?: record, workerLifecycleEvent?: record, workerMessageCode?: record, workerMetrics?: record, workerShutdownNotice?: record, workerThreadScalingReport?: record}
]: any -> record<workerMessageResponses: table<workerHealthReportResponse: record, workerMetricsResponse: record, workerShutdownNoticeResponse: record, workerThreadScalingReportResponse: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/WorkerMessages" $qp)
  let body = {location: $body_location, workerMessages: $workerMessages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Launch a job with a FlexTemplate.
#
# POST /v1b3/projects/{projectId}/locations/{location}/flexTemplates:launch
# operationId: dataflow.projects.locations.flexTemplates.launch
# --launchParameter shape: {containerSpec?: record, containerSpecGcsPath?: string, environment?: record, jobName?: string, launchOptions?: record, parameters?: record, transformNameMappings?: record, update?: bool}
export def "v1b3-projects-locations-flex-templates-launch dataflowprojectslocationsflexTemplateslaunch" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --launchParameter: record # Launch FlexTemplate Parameter. — shape: {containerSpec?: record, containerSpecGcsPath?: string, environment?: record, jobName?: string, launchOptions?: record, parameters?: record, transformNameMappings?: record, update?: bool}
  --validateOnly: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
]: any -> record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/flexTemplates:launch" $qp)
  let body = {launchParameter: $launchParameter, validateOnly: $validateOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the jobs of a project. To list the jobs of a project in a region, we recommend using `projects.locations.jobs.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). To list the all jobs across all regions, use `projects.jobs.aggregated`. Using `projects.jobs.list` is not recommended, as you can only get the list of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs
# operationId: dataflow.projects.locations.jobs.list
export def "v1b3-projects-locations-jobs dataflowprojectslocationsjobslist" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string@filter-completer # The kind of filter to use.
  --name: string # Optional. The job name. Optional.
  --pageSize: int # If there are many jobs, limit response to at most this many. The actual number of jobs returned will be the lesser of max_responses and an unspecified server-defined limit.
  --pageToken: string # Set this to the 'next_page_token' field of a previous response to request additional results in a long list.
  --view: string@view-completer # Deprecated. ListJobs always returns summaries now. Use GetJob for other JobViews.
]: nothing -> record<failedLocation: table<name: string>, jobs: table<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record, executionInfo: record, id: string, jobMetadata: record, labels: record, location: string, name: string, pipelineDescription: record, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list, startTime: string, steps: list, stepsLocation: string, tempFiles: list, transformNameMapping: record, type: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Cloud Dataflow job. To create a job, we recommend using `projects.locations.jobs.create` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.create` is not recommended, as your job will always start in `us-central1`. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs
# operationId: dataflow.projects.locations.jobs.create
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-locations-jobs dataflowprojectslocationsjobscreate" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --replaceJobId: string # Deprecated. This field is now in the Job message.
  --view: string@view-completer # The level of information requested in response.
  --clientRequestId: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --createTime: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --createdFromSnapshotId: string # If this is specified, the job's initial state is populated from the given snapshot.
  --currentState: string@currentState-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --currentStateTime: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --executionInfo: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --jobMetadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipelineDescription: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-projectId: string # The ID of the Cloud Platform project that the job belongs to.
  --replaceJobId: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replacedByJobId: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requestedState: string@requestedState-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfiesPzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stageStates: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --startTime: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --stepsLocation: string # The Cloud Storage location where the steps are stored.
  --tempFiles: list # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transformNameMapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "replaceJobId" $replaceJobId "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs" $qp)
  let body = {clientRequestId: $clientRequestId, createTime: $createTime, createdFromSnapshotId: $createdFromSnapshotId, currentState: $currentState, currentStateTime: $currentStateTime, environment: $environment, executionInfo: $executionInfo, id: $id, jobMetadata: $jobMetadata, labels: $labels, location: $body_location, name: $name, pipelineDescription: $pipelineDescription, projectId: $body_projectId, replaceJobId: $replaceJobId, replacedByJobId: $replacedByJobId, requestedState: $requestedState, satisfiesPzs: $satisfiesPzs, stageStates: $stageStates, startTime: $startTime, steps: $steps, stepsLocation: $stepsLocation, tempFiles: $tempFiles, transformNameMapping: $transformNameMapping, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the state of the specified Cloud Dataflow job. To get the state of a job, we recommend using `projects.locations.jobs.get` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.get` is not recommended, as you can only get the state of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}
# operationId: dataflow.projects.locations.jobs.get
export def "v1b3-projects-locations-jobs dataflowprojectslocationsjobsget" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --view: string@view-completer # The level of information requested in response.
]: nothing -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the state of an existing Cloud Dataflow job. To update the state of an existing job, we recommend using `projects.locations.jobs.update` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.update` is not recommended, as you can only update the state of jobs that are running in `us-central1`.
#
# PUT /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}
# operationId: dataflow.projects.locations.jobs.update
# --environment shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
# --executionInfo shape: {stages?: record}
# --jobMetadata shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
# --pipelineDescription shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
# --stageStates item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
# --steps item shape: {kind?: string, name?: string, properties?: record}
export def "v1b3-projects-locations-jobs dataflowprojectslocationsjobsupdate" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --updateMask: string # The list of fields to update relative to Job. If empty, only RequestedJobState will be considered for update. If the FieldMask is not empty and RequestedJobState is none/empty, The fields specified in the update mask will be the only ones considered for update. If both RequestedJobState and update_mask are specified, we will first handle RequestedJobState and then the update_mask fields.
  --clientRequestId: string # The client's unique identifier of the job, re-used across retried attempts. If this field is set, the service will ensure its uniqueness. The request to create a job will fail if the service has knowledge of a previously submitted job with the same client's ID and job name. The caller may use this field to ensure idempotence of job creation across retried attempts to create a job. By default, the field is empty and, in that case, the service ignores it.
  --createTime: string # The timestamp when the job was initially created. Immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --createdFromSnapshotId: string # If this is specified, the job's initial state is populated from the given snapshot.
  --currentState: string@currentState-completer # The current state of the job. Jobs are created in the `JOB_STATE_STOPPED` state unless otherwise specified. A job in the `JOB_STATE_RUNNING` state may asynchronously enter a terminal state. After a job has reached a terminal state, no further state updates may be made. This field may be mutated by the Cloud Dataflow service; callers cannot mutate it.
  --currentStateTime: string # The timestamp associated with the current state. (format: google-datetime)
  --environment: record # Describes the environment in which a Dataflow Job runs. — shape: {clusterManagerApiService?: string, dataset?: string, debugOptions?: record, experiments?: list, flexResourceSchedulingGoal?: "FLEXRS_UNSPECIFIED"|"FLEXRS_SPEED_OPTIMIZED"|"FLEXRS_COST_OPTIMIZED", internalExperiments?: record, sdkPipelineOptions?: record, serviceAccountEmail?: string, serviceKmsKeyName?: string, serviceOptions?: list, tempStoragePrefix?: string, userAgent?: record, version?: record, workerPools?: list, workerRegion?: string, workerZone?: string}
  --executionInfo: record # Additional information about how a Cloud Dataflow job will be executed that isn't contained in the submitted job. — shape: {stages?: record}
  --id: string # The unique ID of this job. This field is set by the Cloud Dataflow service when the Job is created, and is immutable for the life of the job.
  --jobMetadata: record # Metadata available primarily for filtering jobs. Will be included in the ListJob response and Job SUMMARY view. — shape: {bigTableDetails?: list, bigqueryDetails?: list, datastoreDetails?: list, fileDetails?: list, pubsubDetails?: list, sdkVersion?: record, spannerDetails?: list, userDisplayProperties?: record}
  --labels: record # User-defined labels for this job. The labels map can contain no more than 64 entries. Entries of the labels map are UTF8 strings that comply with the following restrictions: * Keys must conform to regexp: \p{Ll}\p{Lo}{0,62} * Values must conform to regexp: [\p{Ll}\p{Lo}\p{N}_-]{0,63} * Both keys and values are additionally constrained to be <= 128 bytes in size.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains this job.
  --name: string # The user-specified Cloud Dataflow job name. Only one Job with a given name can exist in a project within one region at any given time. Jobs in different regions can have the same name. If a caller attempts to create a Job with the same name as an already-existing Job, the attempt returns the existing Job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --pipelineDescription: record # A descriptive representation of submitted pipeline as well as the executed form. This data is provided by the Dataflow service for ease of visualizing the pipeline and interpreting Dataflow provided metrics. — shape: {displayData?: list, executionPipelineStage?: list, originalPipelineTransform?: list, stepNamesHash?: string}
  --body-projectId: string # The ID of the Cloud Platform project that the job belongs to.
  --replaceJobId: string # If this job is an update of an existing job, this field is the job ID of the job it replaced. When sending a `CreateJobRequest`, you can update a job by specifying it here. The job named here is stopped, and its intermediate state is transferred to this job.
  --replacedByJobId: string # If another job is an update of this job (and thus, this job is in `JOB_STATE_UPDATED`), this field contains the ID of that job.
  --requestedState: string@requestedState-completer # The job's requested state. `UpdateJob` may be used to switch between the `JOB_STATE_STOPPED` and `JOB_STATE_RUNNING` states, by setting requested_state. `UpdateJob` may also be used to directly set a job's requested state to `JOB_STATE_CANCELLED` or `JOB_STATE_DONE`, irrevocably terminating the job if it has not already reached a terminal state.
  --satisfiesPzs: oneof<nothing, bool> # Reserved for future use. This field is set only in responses from the server; it is ignored if it is set in any requests.
  --stageStates: list # This field may be mutated by the Cloud Dataflow service; callers cannot mutate it. — item shape: {currentStateTime?: string, executionStageName?: string, executionStageState?: "JOB_STATE_UNKNOWN"|"JOB_STATE_STOPPED"|"JOB_STATE_RUNNING"|"JOB_STATE_DONE"|"JOB_STATE_FAILED"|"JOB_STATE_CANCELLED"|"JOB_STATE_UPDATED"|"JOB_STATE_DRAINING"|"JOB_STATE_DRAINED"|"JOB_STATE_PENDING"|"JOB_STATE_CANCELLING"|"JOB_STATE_QUEUED"|"JOB_STATE_RESOURCE_CLEANING_UP"}
  --startTime: string # The timestamp when the job was started (transitioned to JOB_STATE_PENDING). Flexible resource scheduling jobs are started with some delay after job creation, so start_time is unset before start and is updated when the job is started by the Cloud Dataflow service. For other jobs, start_time always equals to create_time and is immutable and set by the Cloud Dataflow service. (format: google-datetime)
  --steps: list # Exactly one of step or steps_location should be specified. The top-level steps that constitute the entire job. Only retrieved with JOB_VIEW_ALL. — item shape: {kind?: string, name?: string, properties?: record}
  --stepsLocation: string # The Cloud Storage location where the steps are stored.
  --tempFiles: list # A set of files the system should be aware of that are used for temporary storage. These temporary files will be removed on job completion. No duplicates are allowed. No file patterns are supported. The supported files are: Google Cloud Storage: storage.googleapis.com/{bucket}/{object} bucket.storage.googleapis.com/{object}
  --transformNameMapping: record # The map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --type: string@type-completer # The type of Cloud Dataflow job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)" $qp)
  let body = {clientRequestId: $clientRequestId, createTime: $createTime, createdFromSnapshotId: $createdFromSnapshotId, currentState: $currentState, currentStateTime: $currentStateTime, environment: $environment, executionInfo: $executionInfo, id: $id, jobMetadata: $jobMetadata, labels: $labels, location: $body_location, name: $name, pipelineDescription: $pipelineDescription, projectId: $body_projectId, replaceJobId: $replaceJobId, replacedByJobId: $replacedByJobId, requestedState: $requestedState, satisfiesPzs: $satisfiesPzs, stageStates: $stageStates, startTime: $startTime, steps: $steps, stepsLocation: $stepsLocation, tempFiles: $tempFiles, transformNameMapping: $transformNameMapping, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get encoded debug configuration for component. Not cacheable.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/getConfig
# operationId: dataflow.projects.locations.jobs.debug.getConfig
export def "v1b3-projects-locations-jobs-debug-get-config dataflowprojectslocationsjobsdebuggetConfig" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --componentId: string # The internal component id for which debug configuration is requested.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --workerId: string # The worker id, i.e., VM hostname.
]: any -> record<config: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/debug/getConfig" $qp)
  let body = {componentId: $componentId, location: $body_location, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send encoded debug capture data for component.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/debug/sendCapture
# operationId: dataflow.projects.locations.jobs.debug.sendCapture
export def "v1b3-projects-locations-jobs-debug-send-capture dataflowprojectslocationsjobsdebugsendCapture" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --componentId: string # The internal component id for which debug information is sent.
  --data: string # The encoded debug information.
  --dataFormat: string@dataFormat-completer # Format for the data field above (id=5).
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the job specified by job_id.
  --workerId: string # The worker id, i.e., VM hostname.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/debug/sendCapture" $qp)
  let body = {componentId: $componentId, data: $data, dataFormat: $dataFormat, location: $body_location, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request detailed information about the execution status of the job. EXPERIMENTAL. This API is subject to change or removal without notice.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/executionDetails
# operationId: dataflow.projects.locations.jobs.getExecutionDetails
export def "v1b3-projects-locations-jobs-execution-details dataflowprojectslocationsjobsgetExecutionDetails" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # If specified, determines the maximum number of stages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --pageToken: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
]: nothing -> record<nextPageToken: string, stages: table<endTime: string, metrics: list, progress: record, stageId: string, startTime: string, state: string, stragglerSummary: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/executionDetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.messages.list` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.messages.list` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/messages
# operationId: dataflow.projects.locations.jobs.messages.list
export def "v1b3-projects-locations-jobs-messages dataflowprojectslocationsjobsmessageslist" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --endTime: string # Return only messages with timestamps < end_time. The default is now (i.e. return up to the latest messages available).
  --minimumImportance: string@minimumImportance-completer # Filter to only get messages with importance >= level
  --pageSize: int # If specified, determines the maximum number of messages to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --pageToken: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --startTime: string # If specified, return only messages with timestamps >= start_time. The default is the job creation time (i.e. beginning of messages).
]: nothing -> record<autoscalingEvents: table<currentNumWorkers: string, description: record, eventType: string, targetNumWorkers: string, time: string, workerPool: string>, jobMessages: table<id: string, messageImportance: string, messageText: string, time: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "minimumImportance" $minimumImportance "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request the job status. To request the status of a job, we recommend using `projects.locations.jobs.getMetrics` with a [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints). Using `projects.jobs.getMetrics` is not recommended, as you can only request the status of jobs that are running in `us-central1`.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/metrics
# operationId: dataflow.projects.locations.jobs.getMetrics
export def "v1b3-projects-locations-jobs-metrics dataflowprojectslocationsjobsgetMetrics" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --startTime: string # Return only metric data that has changed since this time. Default is to return all information about all metrics for the job.
]: nothing -> record<metricTime: string, metrics: table<cumulative: bool, distribution: any, gauge: any, internal: any, kind: string, meanCount: any, meanSum: any, name: record, scalar: any, set: any, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/snapshots
# operationId: dataflow.projects.locations.jobs.snapshots.list
export def "v1b3-projects-locations-jobs-snapshots dataflowprojectslocationsjobssnapshotslist" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request detailed information about the execution status of a stage of the job. EXPERIMENTAL. This API is subject to change or removal without notice.
#
# GET /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/stages/{stageId}/executionDetails
# operationId: dataflow.projects.locations.jobs.stages.getExecutionDetails
export def "v1b3-projects-locations-jobs-stages-execution-details dataflowprojectslocationsjobsstagesgetExecutionDetails" [
  projectId: string
  location: string
  jobId: string
  stageId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --endTime: string # Upper time bound of work items to include, by start time.
  --pageSize: int # If specified, determines the maximum number of work items to return. If unspecified, the service may choose an appropriate default, or may return an arbitrarily large number of results.
  --pageToken: string # If supplied, this should be the value of next_page_token returned by an earlier call. This will cause the next page of results to be returned.
  --startTime: string # Lower time bound of work items to include, by start time.
]: nothing -> record<nextPageToken: string, workers: table<workItems: list, workerName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/stages/($stageId)/executionDetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Leases a dataflow WorkItem to run.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:lease
# operationId: dataflow.projects.locations.jobs.workItems.lease
export def "v1b3-projects-locations-jobs-work-items-lease dataflowprojectslocationsjobsworkItemslease" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --currentWorkerTime: string # The current timestamp at the worker. (format: google-datetime)
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --requestedLeaseDuration: string # The initial lease period. (format: google-duration)
  --unifiedWorkerRequest: record # Untranslated bag-of-bytes WorkRequest from UnifiedWorker.
  --workItemTypes: list # Filter for WorkItem type.
  --workerCapabilities: list # Worker capabilities. WorkItems might be limited to workers with specific capabilities.
  --workerId: string # Identifies the worker leasing work -- typically the ID of the virtual machine running the worker.
]: any -> record<unifiedWorkerResponse: record, workItems: table<configuration: string, id: string, initialReportIndex: string, jobId: string, leaseExpireTime: string, mapTask: record, packages: list, projectId: string, reportStatusInterval: string, seqMapTask: record, shellTask: record, sourceOperationTask: record, streamingComputationTask: record, streamingConfigTask: record, streamingSetupTask: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/workItems:lease" $qp)
  let body = {currentWorkerTime: $currentWorkerTime, location: $body_location, requestedLeaseDuration: $requestedLeaseDuration, unifiedWorkerRequest: $unifiedWorkerRequest, workItemTypes: $workItemTypes, workerCapabilities: $workerCapabilities, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reports the status of dataflow WorkItems leased by a worker.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}/workItems:reportStatus
# operationId: dataflow.projects.locations.jobs.workItems.reportStatus
# --workItemStatuses item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
export def "v1b3-projects-locations-jobs-work-items-report-status dataflowprojectslocationsjobsworkItemsreportStatus" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --currentWorkerTime: string # The current timestamp at the worker. (format: google-datetime)
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) that contains the WorkItem's job.
  --unifiedWorkerRequest: record # Untranslated bag-of-bytes WorkProgressUpdateRequest from UnifiedWorker.
  --workItemStatuses: list # The order is unimportant, except that the order of the WorkItemServiceState messages in the ReportWorkItemStatusResponse corresponds to the order of WorkItemStatus messages here. — item shape: {completed?: bool, counterUpdates?: list, dynamicSourceSplit?: record, errors?: list, metricUpdates?: list, progress?: record, reportIndex?: string, reportedProgress?: record, requestedLeaseDuration?: string, sourceFork?: record, sourceOperationResponse?: record, stopPosition?: record, totalThrottlerWaitTimeSeconds?: float, workItemId?: string}
  --workerId: string # The ID of the worker reporting the WorkItem status. If this does not match the ID of the worker which the Dataflow service believes currently has the lease on the WorkItem, the report will be dropped (with an error response).
]: any -> record<unifiedWorkerResponse: record, workItemServiceStates: table<completeWorkStatus: record, harnessData: record, hotKeyDetection: record, leaseExpireTime: string, metricShortId: list, nextReportIndex: string, reportStatusInterval: string, splitRequest: record, suggestedStopPoint: record, suggestedStopPosition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId)/workItems:reportStatus" $qp)
  let body = {currentWorkerTime: $currentWorkerTime, location: $body_location, unifiedWorkerRequest: $unifiedWorkerRequest, workItemStatuses: $workItemStatuses, workerId: $workerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Snapshot the state of a streaming job.
#
# POST /v1b3/projects/{projectId}/locations/{location}/jobs/{jobId}:snapshot
# operationId: dataflow.projects.locations.jobs.snapshot
export def "v1b3-projects-locations-jobs dataflowprojectslocationsjobssnapshot" [
  projectId: string
  location: string
  jobId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --description: string # User specified description of the snapshot. Maybe empty.
  --body-location: string # The location that contains this job.
  --snapshotSources: oneof<nothing, bool> # If true, perform snapshots for sources which support this.
  --ttl: string # TTL for the snapshot. (format: google-duration)
]: any -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/jobs/($jobId):snapshot" $qp)
  let body = {description: $description, location: $body_location, snapshotSources: $snapshotSources, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/locations/{location}/snapshots
# operationId: dataflow.projects.locations.snapshots.list
export def "v1b3-projects-locations-snapshots dataflowprojectslocationssnapshotslist" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --jobId: string # If specified, list snapshots created from this job.
]: nothing -> record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "jobId" $jobId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a snapshot.
#
# DELETE /v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}
# operationId: dataflow.projects.locations.snapshots.delete
export def "v1b3-projects-locations-snapshots dataflowprojectslocationssnapshotsdelete" [
  projectId: string
  location: string
  snapshotId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/snapshots/($snapshotId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a snapshot.
#
# GET /v1b3/projects/{projectId}/locations/{location}/snapshots/{snapshotId}
# operationId: dataflow.projects.locations.snapshots.get
export def "v1b3-projects-locations-snapshots dataflowprojectslocationssnapshotsget" [
  projectId: string
  location: string
  snapshotId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/snapshots/($snapshotId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Cloud Dataflow job from a template. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/locations/{location}/templates
# operationId: dataflow.projects.locations.templates.create
# --environment shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-locations-templates dataflowprojectslocationstemplatescreate" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --gcsPath: string # Required. A Cloud Storage path to the template from which to create the job. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --jobName: string # Required. The job name to use for the created job.
  --body-location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --parameters: record # The runtime parameters to pass to the job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/templates" $qp)
  let body = {environment: $environment, gcsPath: $gcsPath, jobName: $jobName, location: $body_location, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the template associated with a template.
#
# GET /v1b3/projects/{projectId}/locations/{location}/templates:get
# operationId: dataflow.projects.locations.templates.get
export def "v1b3-projects-locations-templates-get dataflowprojectslocationstemplatesget" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gcsPath: string # Required. A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --view: string@view-completer-1 # The view to retrieve. Defaults to METADATA_ONLY.
]: nothing -> record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "gcsPath" $gcsPath "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/templates:get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Launch a template.
#
# POST /v1b3/projects/{projectId}/locations/{location}/templates:launch
# operationId: dataflow.projects.locations.templates.launch
# --environment shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-locations-templates-launch dataflowprojectslocationstemplateslaunch" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dynamicTemplategcsPath: string # Path to dynamic template spec file on Cloud Storage. The file must be a Json serialized DynamicTemplateFieSpec object.
  --dynamicTemplatestagingLocation: string # Cloud Storage path for staging dependencies. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --gcsPath: string # A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --validateOnly: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --jobName: string # Required. The job name to use for the created job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --parameters: record # The runtime parameters to pass to the job.
  --transformNameMapping: record # Only applicable when updating a pipeline. Map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --update: oneof<nothing, bool> # If set, replace the existing pipeline with the name specified by jobName with this pipeline, preserving state.
]: any -> record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "dynamicTemplate.gcsPath" $dynamicTemplategcsPath "scalar") (serialize-qp "dynamicTemplate.stagingLocation" $dynamicTemplatestagingLocation "scalar") (serialize-qp "gcsPath" $gcsPath "scalar") (serialize-qp "validateOnly" $validateOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/locations/($location)/templates:launch" $qp)
  let body = {environment: $environment, jobName: $jobName, parameters: $parameters, transformNameMapping: $transformNameMapping, update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a snapshot.
#
# DELETE /v1b3/projects/{projectId}/snapshots
# operationId: dataflow.projects.deleteSnapshots
export def "v1b3-projects-snapshots dataflowprojectsdeleteSnapshots" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The location that contains this snapshot.
  --snapshotId: string # The ID of the snapshot.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "snapshotId" $snapshotId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists snapshots.
#
# GET /v1b3/projects/{projectId}/snapshots
# operationId: dataflow.projects.snapshots.list
export def "v1b3-projects-snapshots dataflowprojectssnapshotslist" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --jobId: string # If specified, list snapshots created from this job.
  --location: string # The location to list snapshots in.
]: nothing -> record<snapshots: table<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: list, region: string, sourceJobId: string, state: string, ttl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "jobId" $jobId "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a snapshot.
#
# GET /v1b3/projects/{projectId}/snapshots/{snapshotId}
# operationId: dataflow.projects.snapshots.get
export def "v1b3-projects-snapshots dataflowprojectssnapshotsget" [
  projectId: string
  snapshotId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --location: string # The location that contains this snapshot.
]: nothing -> record<creationTime: string, description: string, diskSizeBytes: string, id: string, projectId: string, pubsubMetadata: table<expireTime: string, snapshotName: string, topicName: string>, region: string, sourceJobId: string, state: string, ttl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/snapshots/($snapshotId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Cloud Dataflow job from a template. Do not enter confidential information when you supply string values using the API.
#
# POST /v1b3/projects/{projectId}/templates
# operationId: dataflow.projects.templates.create
# --environment shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-templates dataflowprojectstemplatescreate" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --gcsPath: string # Required. A Cloud Storage path to the template from which to create the job. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --jobName: string # Required. The job name to use for the created job.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --parameters: record # The runtime parameters to pass to the job.
]: any -> record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record<enableHotKeyLogging: bool>, experiments: list<string>, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list<string>, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list<record>, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list<record>, bigqueryDetails: list<record>, datastoreDetails: list<record>, fileDetails: list<record>, pubsubDetails: list<record>, sdkVersion: record<sdkSupportStatus: string, version: string, versionDisplayName: string>, spannerDetails: list<record>, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list<record>, executionPipelineStage: list<record>, originalPipelineTransform: list<record>, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: table<currentStateTime: string, executionStageName: string, executionStageState: string>, startTime: string, steps: table<kind: string, name: string, properties: record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/templates" $qp)
  let body = {environment: $environment, gcsPath: $gcsPath, jobName: $jobName, location: $location, parameters: $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the template associated with a template.
#
# GET /v1b3/projects/{projectId}/templates:get
# operationId: dataflow.projects.templates.get
export def "v1b3-projects-templates-get dataflowprojectstemplatesget" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --gcsPath: string # Required. A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --view: string@view-completer-1 # The view to retrieve. Defaults to METADATA_ONLY.
]: nothing -> record<metadata: record<description: string, name: string, parameters: list<record>>, runtimeMetadata: record<parameters: list<record>, sdkInfo: record<language: string, version: string>>, status: record<code: int, details: list<record>, message: string>, templateType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "gcsPath" $gcsPath "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/templates:get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Launch a template.
#
# POST /v1b3/projects/{projectId}/templates:launch
# operationId: dataflow.projects.templates.launch
# --environment shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
export def "v1b3-projects-templates-launch dataflowprojectstemplateslaunch" [
  projectId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dynamicTemplategcsPath: string # Path to dynamic template spec file on Cloud Storage. The file must be a Json serialized DynamicTemplateFieSpec object.
  --dynamicTemplatestagingLocation: string # Cloud Storage path for staging dependencies. Must be a valid Cloud Storage URL, beginning with `gs://`.
  --gcsPath: string # A Cloud Storage path to the template from which to create the job. Must be valid Cloud Storage URL, beginning with 'gs://'.
  --location: string # The [regional endpoint] (https://cloud.google.com/dataflow/docs/concepts/regional-endpoints) to which to direct the request.
  --validateOnly: oneof<nothing, bool> # If true, the request is validated but not actually executed. Defaults to false.
  --environment: record # The environment values to set at runtime. — shape: {additionalExperiments?: list, additionalUserLabels?: record, bypassTempDirValidation?: bool, enableStreamingEngine?: bool, ipConfiguration?: "WORKER_IP_UNSPECIFIED"|"WORKER_IP_PUBLIC"|"WORKER_IP_PRIVATE", kmsKeyName?: string, machineType?: string, maxWorkers?: int, network?: string, numWorkers?: int, serviceAccountEmail?: string, subnetwork?: string, tempLocation?: string, workerRegion?: string, workerZone?: string, zone?: string}
  --jobName: string # Required. The job name to use for the created job. The name must match the regular expression `[a-z]([-a-z0-9]{0,1022}[a-z0-9])?`
  --parameters: record # The runtime parameters to pass to the job.
  --transformNameMapping: record # Only applicable when updating a pipeline. Map of transform name prefixes of the job to be replaced to the corresponding name prefixes of the new job.
  --update: oneof<nothing, bool> # If set, replace the existing pipeline with the name specified by jobName with this pipeline, preserving state.
]: any -> record<job: record<clientRequestId: string, createTime: string, createdFromSnapshotId: string, currentState: string, currentStateTime: string, environment: record<clusterManagerApiService: string, dataset: string, debugOptions: record, experiments: list, flexResourceSchedulingGoal: string, internalExperiments: record, sdkPipelineOptions: record, serviceAccountEmail: string, serviceKmsKeyName: string, serviceOptions: list, shuffleMode: string, tempStoragePrefix: string, userAgent: record, version: record, workerPools: list, workerRegion: string, workerZone: string>, executionInfo: record<stages: record>, id: string, jobMetadata: record<bigTableDetails: list, bigqueryDetails: list, datastoreDetails: list, fileDetails: list, pubsubDetails: list, sdkVersion: record, spannerDetails: list, userDisplayProperties: record>, labels: record, location: string, name: string, pipelineDescription: record<displayData: list, executionPipelineStage: list, originalPipelineTransform: list, stepNamesHash: string>, projectId: string, replaceJobId: string, replacedByJobId: string, requestedState: string, satisfiesPzs: bool, stageStates: list<record>, startTime: string, steps: list<record>, stepsLocation: string, tempFiles: list<string>, transformNameMapping: record, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "dynamicTemplate.gcsPath" $dynamicTemplategcsPath "scalar") (serialize-qp "dynamicTemplate.stagingLocation" $dynamicTemplatestagingLocation "scalar") (serialize-qp "gcsPath" $gcsPath "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "validateOnly" $validateOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1b3/projects/($projectId)/templates:launch" $qp)
  let body = {environment: $environment, jobName: $jobName, parameters: $parameters, transformNameMapping: $transformNameMapping, update: $update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
