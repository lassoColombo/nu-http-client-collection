# Auto-generated client for AWS IoT Jobs Data Plane v2017-09-29
# Source: https://api.apis.guru/v2/specs/amazonaws.com/iot-jobs-data/2017-09-29/openapi.json
# Auth: --token flag or $env.AWS_IOT_JOBS_DATA_PLANE_TOKEN

const BASE_URL = "http://data.jobs.iot.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_IOT_JOBS_DATA_PLANE_TOKEN | default "" }
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

def base-url-completer [] { ["http://data.jobs.iot.us-east-1.amazonaws.com" "http://data.jobs.iot.us-east-2.amazonaws.com" "http://data.jobs.iot.us-west-1.amazonaws.com" "http://data.jobs.iot.us-west-2.amazonaws.com" "http://data.jobs.iot.us-gov-west-1.amazonaws.com" "http://data.jobs.iot.us-gov-east-1.amazonaws.com" "http://data.jobs.iot.ca-central-1.amazonaws.com" "http://data.jobs.iot.eu-north-1.amazonaws.com" "http://data.jobs.iot.eu-west-1.amazonaws.com" "http://data.jobs.iot.eu-west-2.amazonaws.com" "http://data.jobs.iot.eu-west-3.amazonaws.com" "http://data.jobs.iot.eu-central-1.amazonaws.com" "http://data.jobs.iot.eu-south-1.amazonaws.com" "http://data.jobs.iot.af-south-1.amazonaws.com" "http://data.jobs.iot.ap-northeast-1.amazonaws.com" "http://data.jobs.iot.ap-northeast-2.amazonaws.com" "http://data.jobs.iot.ap-northeast-3.amazonaws.com" "http://data.jobs.iot.ap-southeast-1.amazonaws.com" "http://data.jobs.iot.ap-southeast-2.amazonaws.com" "http://data.jobs.iot.ap-east-1.amazonaws.com" "http://data.jobs.iot.ap-south-1.amazonaws.com" "http://data.jobs.iot.sa-east-1.amazonaws.com" "http://data.jobs.iot.me-south-1.amazonaws.com" "https://data.jobs.iot.us-east-1.amazonaws.com" "https://data.jobs.iot.us-east-2.amazonaws.com" "https://data.jobs.iot.us-west-1.amazonaws.com" "https://data.jobs.iot.us-west-2.amazonaws.com" "https://data.jobs.iot.us-gov-west-1.amazonaws.com" "https://data.jobs.iot.us-gov-east-1.amazonaws.com" "https://data.jobs.iot.ca-central-1.amazonaws.com" "https://data.jobs.iot.eu-north-1.amazonaws.com" "https://data.jobs.iot.eu-west-1.amazonaws.com" "https://data.jobs.iot.eu-west-2.amazonaws.com" "https://data.jobs.iot.eu-west-3.amazonaws.com" "https://data.jobs.iot.eu-central-1.amazonaws.com" "https://data.jobs.iot.eu-south-1.amazonaws.com" "https://data.jobs.iot.af-south-1.amazonaws.com" "https://data.jobs.iot.ap-northeast-1.amazonaws.com" "https://data.jobs.iot.ap-northeast-2.amazonaws.com" "https://data.jobs.iot.ap-northeast-3.amazonaws.com" "https://data.jobs.iot.ap-southeast-1.amazonaws.com" "https://data.jobs.iot.ap-southeast-2.amazonaws.com" "https://data.jobs.iot.ap-east-1.amazonaws.com" "https://data.jobs.iot.ap-south-1.amazonaws.com" "https://data.jobs.iot.sa-east-1.amazonaws.com" "https://data.jobs.iot.me-south-1.amazonaws.com" "http://data.jobs.iot.cn-north-1.amazonaws.com.cn" "http://data.jobs.iot.cn-northwest-1.amazonaws.com.cn" "https://data.jobs.iot.cn-north-1.amazonaws.com.cn" "https://data.jobs.iot.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["CANCELED" "FAILED" "IN_PROGRESS" "QUEUED" "REJECTED" "REMOVED" "SUCCEEDED" "TIMED_OUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "things-jobs get-execution" } } | get name | first)
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
export def "things-jobs get-execution" [
  thing_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($thing_name | is-empty) { error make --unspanned { msg: "path parameter 'thingName' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let qp = [(serialize-qp "includeJobDocument" $include_job_document "scalar") (serialize-qp "executionNumber" $execution_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name), job_id: (encode-path-segment $job_id)} | format pattern "/things/{thing_name}/jobs/{job_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"includeJobDocument": $include_job_document, "executionNumber": $execution_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates the status of a job execution.
#
# POST /things/{thingName}/jobs/{jobId}
# operationId: UpdateJobExecution
export def "things-jobs update-execution" [
  thing_name: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  status: string@status-completer # The new status for the job execution (IN_PROGRESS, FAILED, SUCCESS, or REJECTED). This must be specified on every update.
  --status-details: record # Optional. A collection of name/value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
  --step-timeout-in-minutes: int # Specifies the amount of time this device has to finish execution of this job. If the job execution status is not set to a terminal state before this timer expires, or before the timer is reset (by again calling UpdateJobExecution, setting the status to IN_PROGRESS and specifying a new timeout value in this field) the job execution status will be automatically set to TIMED_OUT. Note that setting or resetting this timeout has no effect on that job execution timeout which may have been specified when the job was created (CreateJob using field timeoutConfig).
  --expected-version: int # Optional. The expected current version of the job execution. Each time you update the job execution, its version is incremented. If the version of the job execution stored in Jobs does not match, the update is rejected with a VersionMismatch error, and an ErrorResponse that contains the current job execution status data is returned. (This makes it unnecessary to perform a separate DescribeJobExecution request in order to obtain the job execution status data.)
  --include-job-execution-state: oneof<nothing, bool> # Optional. When included and set to true, the response contains the JobExecutionState data. The default is false.
  --include-job-document: oneof<nothing, bool> # Optional. When set to true, the response contains the job document. The default is false.
  --execution-number: int # Optional. A number that identifies a particular job execution on a particular device.
]: any -> record<executionState: record<status: record, statusDetails: record, versionNumber: record>, jobDocument: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($thing_name | is-empty) { error make --unspanned { msg: "path parameter 'thingName' must be non-empty" } }
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name), job_id: (encode-path-segment $job_id)} | format pattern "/things/{thing_name}/jobs/{job_id}") $auth.query)
  let req_body = {"status": $status, "statusDetails": $status_details, "stepTimeoutInMinutes": $step_timeout_in_minutes, "expectedVersion": $expected_version, "includeJobExecutionState": $include_job_execution_state, "includeJobDocument": $include_job_document, "executionNumber": $execution_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets the list of all jobs for a thing that are not in a terminal status.
#
# GET /things/{thingName}/jobs
# operationId: GetPendingJobExecutions
export def "things-jobs get-pending-executions" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($thing_name | is-empty) { error make --unspanned { msg: "path parameter 'thingName' must be non-empty" } }
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/things/{thing_name}/jobs") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets and starts the next pending (status IN_PROGRESS or QUEUED) job execution for a thing.
#
# PUT /things/{thingName}/jobs/$next
# operationId: StartNextPendingJobExecution
export def "things-jobs-next start-next-pending-execution" [
  thing_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --status-details: record # A collection of name/value pairs that describe the status of the job execution. If not specified, the statusDetails are unchanged.
  --step-timeout-in-minutes: int # Specifies the amount of time this device has to finish execution of this job. If the job execution status is not set to a terminal state before this timer expires, or before the timer is reset (by calling UpdateJobExecution, setting the status to IN_PROGRESS and specifying a new timeout value in field stepTimeoutInMinutes) the job execution status will be automatically set to TIMED_OUT. Note that setting this timeout has no effect on that job execution timeout which may have been specified when the job was created (CreateJob using field timeoutConfig).
]: any -> record<execution: record<jobId: record, thingName: record, status: record, statusDetails: record, queuedAt: record, startedAt: record, lastUpdatedAt: record, approximateSecondsBeforeTimedOut: record, versionNumber: record, executionNumber: record, jobDocument: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($thing_name | is-empty) { error make --unspanned { msg: "path parameter 'thingName' must be non-empty" } }
  let full_url = (build-url $base ({thing_name: (encode-path-segment $thing_name)} | format pattern "/things/{thing_name}/jobs/$next") $auth.query)
  let req_body = {"statusDetails": $status_details, "stepTimeoutInMinutes": $step_timeout_in_minutes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}
