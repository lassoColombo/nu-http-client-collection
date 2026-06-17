# Auto-generated client for AWS IoT Jobs Data Plane v2017-09-29
# Source: https://api.apis.guru/v2/specs/amazonaws.com/iot-jobs-data/2017-09-29/openapi.json
# Auth: --token flag or $env.AWS_IOT_JOBS_DATA_PLANE_TOKEN

const BASE_URL = "http://data.jobs.iot.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_IOT_JOBS_DATA_PLANE_TOKEN | default "" }
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

def base-url-completer [] { ["http://data.jobs.iot.us-east-1.amazonaws.com" "http://data.jobs.iot.us-east-2.amazonaws.com" "http://data.jobs.iot.us-west-1.amazonaws.com" "http://data.jobs.iot.us-west-2.amazonaws.com" "http://data.jobs.iot.us-gov-west-1.amazonaws.com" "http://data.jobs.iot.us-gov-east-1.amazonaws.com" "http://data.jobs.iot.ca-central-1.amazonaws.com" "http://data.jobs.iot.eu-north-1.amazonaws.com" "http://data.jobs.iot.eu-west-1.amazonaws.com" "http://data.jobs.iot.eu-west-2.amazonaws.com" "http://data.jobs.iot.eu-west-3.amazonaws.com" "http://data.jobs.iot.eu-central-1.amazonaws.com" "http://data.jobs.iot.eu-south-1.amazonaws.com" "http://data.jobs.iot.af-south-1.amazonaws.com" "http://data.jobs.iot.ap-northeast-1.amazonaws.com" "http://data.jobs.iot.ap-northeast-2.amazonaws.com" "http://data.jobs.iot.ap-northeast-3.amazonaws.com" "http://data.jobs.iot.ap-southeast-1.amazonaws.com" "http://data.jobs.iot.ap-southeast-2.amazonaws.com" "http://data.jobs.iot.ap-east-1.amazonaws.com" "http://data.jobs.iot.ap-south-1.amazonaws.com" "http://data.jobs.iot.sa-east-1.amazonaws.com" "http://data.jobs.iot.me-south-1.amazonaws.com" "https://data.jobs.iot.us-east-1.amazonaws.com" "https://data.jobs.iot.us-east-2.amazonaws.com" "https://data.jobs.iot.us-west-1.amazonaws.com" "https://data.jobs.iot.us-west-2.amazonaws.com" "https://data.jobs.iot.us-gov-west-1.amazonaws.com" "https://data.jobs.iot.us-gov-east-1.amazonaws.com" "https://data.jobs.iot.ca-central-1.amazonaws.com" "https://data.jobs.iot.eu-north-1.amazonaws.com" "https://data.jobs.iot.eu-west-1.amazonaws.com" "https://data.jobs.iot.eu-west-2.amazonaws.com" "https://data.jobs.iot.eu-west-3.amazonaws.com" "https://data.jobs.iot.eu-central-1.amazonaws.com" "https://data.jobs.iot.eu-south-1.amazonaws.com" "https://data.jobs.iot.af-south-1.amazonaws.com" "https://data.jobs.iot.ap-northeast-1.amazonaws.com" "https://data.jobs.iot.ap-northeast-2.amazonaws.com" "https://data.jobs.iot.ap-northeast-3.amazonaws.com" "https://data.jobs.iot.ap-southeast-1.amazonaws.com" "https://data.jobs.iot.ap-southeast-2.amazonaws.com" "https://data.jobs.iot.ap-east-1.amazonaws.com" "https://data.jobs.iot.ap-south-1.amazonaws.com" "https://data.jobs.iot.sa-east-1.amazonaws.com" "https://data.jobs.iot.me-south-1.amazonaws.com" "http://data.jobs.iot.cn-north-1.amazonaws.com.cn" "http://data.jobs.iot.cn-northwest-1.amazonaws.com.cn" "https://data.jobs.iot.cn-north-1.amazonaws.com.cn" "https://data.jobs.iot.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["CANCELED" "FAILED" "IN_PROGRESS" "QUEUED" "REJECTED" "REMOVED" "SUCCEEDED" "TIMED_OUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "things-jobs get" } } | get name | first)
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

# Gets details of a job execution.
#
# GET /things/{thingName}/jobs/{jobId}
# operationId: DescribeJobExecution
export def "things-jobs get" [
  thing_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-job-document: oneof<nothing, bool> # Optional. When set to true, the response contains the job document. The default is false.
  --execution-number: int # Optional. A number that identifies a particular job execution on a particular device. If not specified, the latest job execution is returned.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<execution: record<jobId: record, thingName: record, status: record, statusDetails: record, queuedAt: record, startedAt: record, lastUpdatedAt: record, approximateSecondsBeforeTimedOut: record, versionNumber: record, executionNumber: record, jobDocument: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeJobDocument" $include_job_document "scalar") (serialize-qp "executionNumber" $execution_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thing_name: $thing_name, job_id: $job_id} | format pattern "/things/{thing_name}/jobs/{job_id}") $qp)
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the status of a job execution.
#
# POST /things/{thingName}/jobs/{jobId}
# operationId: UpdateJobExecution
export def "things-jobs update-job-execution" [
  thing_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  status: string@status-completer # The new status for the job execution (IN_PROGRESS, FAILED, SUCCESS, or REJECTED). This must be specified on every update.
  --status-details: record #  Optional. A collection of name/value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
  --step-timeout-in-minutes: int # Specifies the amount of time this device has to finish execution of this job. If the job execution status is not set to a terminal state before this timer expires, or before the timer is reset (by again calling <code>UpdateJobExecution</code>, setting the status to <code>IN_PROGRESS</code> and specifying a new timeout value in this field) the job execution status will be automatically set to <code>TIMED_OUT</code>. Note that setting or resetting this timeout has no effect on that job execution timeout which may have been specified when the job was created (<code>CreateJob</code> using field <code>timeoutConfig</code>).
  --expected-version: int # Optional. The expected current version of the job execution. Each time you update the job execution, its version is incremented. If the version of the job execution stored in Jobs does not match, the update is rejected with a VersionMismatch error, and an ErrorResponse that contains the current job execution status data is returned. (This makes it unnecessary to perform a separate DescribeJobExecution request in order to obtain the job execution status data.)
  --include-job-execution-state: oneof<nothing, bool> # Optional. When included and set to true, the response contains the JobExecutionState data. The default is false.
  --include-job-document: oneof<nothing, bool> # Optional. When set to true, the response contains the job document. The default is false.
  --execution-number: int # Optional. A number that identifies a particular job execution on a particular device.
]: any -> record<executionState: record<status: record, statusDetails: record, versionNumber: record>, jobDocument: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({thing_name: $thing_name, job_id: $job_id} | format pattern "/things/{thing_name}/jobs/{job_id}"))
  let body = {"status": $status, "statusDetails": $status_details, "stepTimeoutInMinutes": $step_timeout_in_minutes, "expectedVersion": $expected_version, "includeJobExecutionState": $include_job_execution_state, "includeJobDocument": $include_job_document, "executionNumber": $execution_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of all jobs for a thing that are not in a terminal status.
#
# GET /things/{thingName}/jobs
# operationId: GetPendingJobExecutions
export def "things-jobs get-pending-job-executions" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<inProgressJobs: record, queuedJobs: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({thing_name: $thing_name} | format pattern "/things/{thing_name}/jobs"))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
#
# PUT /things/{thingName}/jobs/$next
# operationId: StartNextPendingJobExecution
export def "things-jobs-next start-next-pending-job-execution" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --status-details: record # A collection of name/value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
  --step-timeout-in-minutes: int # Specifies the amount of time this device has to finish execution of this job. If the job execution status is not set to a terminal state before this timer expires, or before the timer is reset (by calling <code>UpdateJobExecution</code>, setting the status to <code>IN_PROGRESS</code> and specifying a new timeout value in field <code>stepTimeoutInMinutes</code>) the job execution status will be automatically set to <code>TIMED_OUT</code>. Note that setting this timeout has no effect on that job execution timeout which may have been specified when the job was created (<code>CreateJob</code> using field <code>timeoutConfig</code>).
]: any -> record<execution: record<jobId: record, thingName: record, status: record, statusDetails: record, queuedAt: record, startedAt: record, lastUpdatedAt: record, approximateSecondsBeforeTimedOut: record, versionNumber: record, executionNumber: record, jobDocument: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({thing_name: $thing_name} | format pattern "/things/{thing_name}/jobs/$next"))
  let body = {"statusDetails": $status_details, "stepTimeoutInMinutes": $step_timeout_in_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
