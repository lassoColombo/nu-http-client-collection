# Auto-generated client for Cloud Testing API v1
# Source: https://api.apis.guru/v2/specs/googleapis.com/testing/v1/openapi.json
# Auth: --token flag or $env.CLOUD_TESTING_API_TOKEN

const BASE_URL = "https://testing.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CLOUD_TESTING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://testing.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def invalid-matrix-details-completer [] { ["BUILT_FOR_IOS_SIMULATOR" "DETAILS_UNAVAILABLE" "DEVICE_ADMIN_RECEIVER" "FORBIDDEN_PERMISSIONS" "INSTRUMENTATION_ORCHESTRATOR_INCOMPATIBLE" "INVALID_APK_PREVIEW_SDK" "INVALID_DIRECTIVE_ACTION" "INVALID_INPUT_APK" "INVALID_MATRIX_DETAILS_UNSPECIFIED" "INVALID_PACKAGE_NAME" "INVALID_RESOURCE_NAME" "INVALID_ROBO_DIRECTIVES" "MALFORMED_APK" "MALFORMED_APP_BUNDLE" "MALFORMED_IPA" "MALFORMED_TEST_APK" "MALFORMED_XC_TEST_ZIP" "MATRIX_TOO_LARGE" "MISSING_URL_SCHEME" "NO_CODE_APK" "NO_INSTRUMENTATION" "NO_LAUNCHER_ACTIVITY" "NO_MANIFEST" "NO_PACKAGE_NAME" "NO_SIGNATURE" "NO_TESTS_IN_XC_TEST_ZIP" "NO_TEST_RUNNER_CLASS" "PLIST_CANNOT_BE_PARSED" "SCENARIO_LABEL_MALFORMED" "SCENARIO_LABEL_NOT_DECLARED" "SCENARIO_NOT_DECLARED" "SERVICE_NOT_ACTIVATED" "TEST_LOOP_INTENT_FILTER_NOT_FOUND" "TEST_NOT_APP_HOSTED" "TEST_ONLY_APK" "TEST_QUOTA_EXCEEDED" "TEST_SAME_AS_APP" "UNKNOWN_PERMISSION_ERROR" "USE_DESTINATION_ARTIFACTS"] }
def outcome-summary-completer [] { ["FAILURE" "INCONCLUSIVE" "OUTCOME_SUMMARY_UNSPECIFIED" "SKIPPED" "SUCCESS"] }
def state-completer [] { ["CANCELLED" "ERROR" "FINISHED" "INCOMPATIBLE_ARCHITECTURE" "INCOMPATIBLE_ENVIRONMENT" "INVALID" "PENDING" "RUNNING" "TEST_STATE_UNSPECIFIED" "UNSUPPORTED_ENVIRONMENT" "VALIDATING"] }
def environment-type-completer [] { ["ANDROID" "DEVICE_IP_BLOCKS" "ENVIRONMENT_TYPE_UNSPECIFIED" "IOS" "NETWORK_CONFIGURATION" "PROVIDED_SOFTWARE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["testing-application-detail-service-get-apk-details" "testing-projects-test-matrices-create" "testing-projects-test-matrices-get" "testing-projects-test-matrices-cancel" "testing-test-environment-catalog-get" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# Gets the details of an Android application APK.
#
# POST /v1/applicationDetailService/getApkDetails
# operationId: testing.applicationDetailService.getApkDetails
export def "testing-application-detail-service-get-apk-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --gcs-path: string # A path to a file in Google Cloud Storage. Example: gs://build-app-1414623860166/app%40debug-unaligned.apk These paths are expected to be url encoded (percent encoding)
]: any -> oneof<record<apkDetail: record<apkManifest: record<applicationLabel: string, intentFilters: list, maxSdkVersion: int, metadata: list, minSdkVersion: int, packageName: string, targetSdkVersion: int, usesFeature: list, usesPermission: list, versionCode: string, versionName: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/applicationDetailService/getApkDetails" $qp $auth.query)
  let req_body = {"gcsPath": $gcs_path} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates and runs a matrix of tests according to the given specifications. Unsupported environments will be returned in the state UNSUPPORTED. A test matrix is limited to use at most 2000 devices in parallel. The returned matrix will not yet contain the executions that will be created for this matrix. That happens later on and will require a call to GetTestMatrix. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed or if the matrix tries to use too many simultaneous devices.
#
# POST /v1/projects/{projectId}/testMatrices
# operationId: testing.projects.testMatrices.create
export def "testing-projects-test-matrices-create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --request-id: string # A string id used to detect duplicated requests. Ids are automatically scoped to a project, so users should ensure the ID is unique per-project. A UUID is recommended. Optional, but strongly recommended.
  --client-info: record # Information about the client which invoked the test. — shape: {clientInfoDetails?: list, name?: string}
  --environment-matrix: record # The matrix of environments in which the test is to be executed. — shape: {androidDeviceList?: record, androidMatrix?: record, iosDeviceList?: record}
  --fail-fast: oneof<nothing, bool> # If true, only a single attempt at most will be made to run each execution/shard in the matrix. Flaky test attempts are not affected. Normally, 2 or more attempts are made if a potential infrastructure issue is detected. This feature is for latency sensitive workloads. The incidence of execution failures may be significantly greater for fail-fast matrices and support is more limited because of that expectation.
  --flaky-test-attempts: int # The number of times a TestExecution should be re-attempted if one or more of its test cases fail for any reason. The maximum number of reruns allowed is 10. Default is 0, which implies no reruns. (format: int32)
  --invalid-matrix-details: string@invalid-matrix-details-completer # Output only. Describes why the matrix is considered invalid. Only useful for matrices in the INVALID state.
  --outcome-summary: string@outcome-summary-completer # Output Only. The overall outcome of the test. Only set when the test matrix state is FINISHED.
  --body-project-id: string # The cloud project that owns the test matrix. (spec name: projectId)
  --result-storage: record # Locations where the results of running the test are stored. — shape: {googleCloudStorage?: record, resultsUrl?: string, toolResultsExecution?: record, toolResultsHistory?: record}
  --state: string@state-completer # Output only. Indicates the current progress of the test matrix.
  --test-executions: list # Output only. The list of test executions that the service creates for this matrix. — item shape: {environment?: record, id?: string, matrixId?: string, projectId?: string, shard?: record, state?: "TEST_STATE_UNSPECIFIED"|"VALIDATING"|"PENDING"|"RUNNING"|"FINISHED"|"ERROR"|"UNSUPPORTED_ENVIRONMENT"|"INCOMPATIBLE_ENVIRONMENT"|"INCOMPATIBLE_ARCHITECTURE"|"CANCELLED"|"INVALID", testDetails?: record, testSpecification?: record, timestamp?: string, toolResultsStep?: record}
  --test-matrix-id: string # Output only. Unique id set by the service.
  --test-specification: record # A description of how to run the test. — shape: {androidInstrumentationTest?: record, androidRoboTest?: record, androidTestLoop?: record, disablePerformanceMetrics?: bool, disableVideoRecording?: bool, iosTestLoop?: record, iosTestSetup?: record, iosXcTest?: record, testSetup?: record, testTimeout?: string}
  --timestamp: string # Output only. The time this test matrix was initially created. (format: google-datetime)
]: any -> oneof<record<clientInfo: record<clientInfoDetails: list<record>, name: string>, environmentMatrix: record<androidDeviceList: record<androidDevices: list>, androidMatrix: record<androidModelIds: list, androidVersionIds: list, locales: list, orientations: list>, iosDeviceList: record<iosDevices: list>>, failFast: bool, flakyTestAttempts: int, invalidMatrixDetails: string, outcomeSummary: string, projectId: string, resultStorage: record<googleCloudStorage: record<gcsPath: string>, resultsUrl: string, toolResultsExecution: record<executionId: string, historyId: string, projectId: string>, toolResultsHistory: record<historyId: string, projectId: string>>, state: string, testExecutions: table<environment: record, id: string, matrixId: string, projectId: string, shard: record, state: string, testDetails: record, testSpecification: record, timestamp: string, toolResultsStep: record>, testMatrixId: string, testSpecification: record<androidInstrumentationTest: record<appApk: record, appBundle: record, appPackageId: string, orchestratorOption: string, shardingOption: record, testApk: record, testPackageId: string, testRunnerClass: string, testTargets: list>, androidRoboTest: record<appApk: record, appBundle: record, appInitialActivity: string, appPackageId: string, maxDepth: int, maxSteps: int, roboDirectives: list, roboMode: string, roboScript: record, startingIntents: list>, androidTestLoop: record<appApk: record, appBundle: record, appPackageId: string, scenarioLabels: list, scenarios: list>, disablePerformanceMetrics: bool, disableVideoRecording: bool, iosTestLoop: record<appBundleId: string, appIpa: record, scenarios: list>, iosTestSetup: record<additionalIpas: list, networkProfile: string, pullDirectories: list, pushFiles: list>, iosXcTest: record<appBundleId: string, testSpecialEntitlements: bool, testsZip: record, xcodeVersion: string, xctestrun: record>, testSetup: record<account: record, additionalApks: list, directoriesToPull: list, dontAutograntPermissions: bool, environmentVariables: list, filesToPush: list, networkProfile: string, systrace: record>, testTimeout: string>, timestamp: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1/projects/{project_id}/testMatrices") $qp $auth.query)
  let req_body = {"clientInfo": $client_info, "environmentMatrix": $environment_matrix, "failFast": $fail_fast, "flakyTestAttempts": $flaky_test_attempts, "invalidMatrixDetails": $invalid_matrix_details, "outcomeSummary": $outcome_summary, "projectId": $body_project_id, "resultStorage": $result_storage, "state": $state, "testExecutions": $test_executions, "testMatrixId": $test_matrix_id, "testSpecification": $test_specification, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "requestId": $request_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Checks the status of a test matrix and the executions once they are created. The test matrix will contain the list of test executions to run if and only if the resultStorage.toolResultsExecution fields have been populated. Note: Flaky test executions may still be added to the matrix at a later stage. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Test Matrix does not exist
#
# GET /v1/projects/{projectId}/testMatrices/{testMatrixId}
# operationId: testing.projects.testMatrices.get
export def "testing-projects-test-matrices-get" [
  project_id: string
  test_matrix_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> oneof<record<clientInfo: record<clientInfoDetails: list<record>, name: string>, environmentMatrix: record<androidDeviceList: record<androidDevices: list>, androidMatrix: record<androidModelIds: list, androidVersionIds: list, locales: list, orientations: list>, iosDeviceList: record<iosDevices: list>>, failFast: bool, flakyTestAttempts: int, invalidMatrixDetails: string, outcomeSummary: string, projectId: string, resultStorage: record<googleCloudStorage: record<gcsPath: string>, resultsUrl: string, toolResultsExecution: record<executionId: string, historyId: string, projectId: string>, toolResultsHistory: record<historyId: string, projectId: string>>, state: string, testExecutions: table<environment: record, id: string, matrixId: string, projectId: string, shard: record, state: string, testDetails: record, testSpecification: record, timestamp: string, toolResultsStep: record>, testMatrixId: string, testSpecification: record<androidInstrumentationTest: record<appApk: record, appBundle: record, appPackageId: string, orchestratorOption: string, shardingOption: record, testApk: record, testPackageId: string, testRunnerClass: string, testTargets: list>, androidRoboTest: record<appApk: record, appBundle: record, appInitialActivity: string, appPackageId: string, maxDepth: int, maxSteps: int, roboDirectives: list, roboMode: string, roboScript: record, startingIntents: list>, androidTestLoop: record<appApk: record, appBundle: record, appPackageId: string, scenarioLabels: list, scenarios: list>, disablePerformanceMetrics: bool, disableVideoRecording: bool, iosTestLoop: record<appBundleId: string, appIpa: record, scenarios: list>, iosTestSetup: record<additionalIpas: list, networkProfile: string, pullDirectories: list, pushFiles: list>, iosXcTest: record<appBundleId: string, testSpecialEntitlements: bool, testsZip: record, xcodeVersion: string, xctestrun: record>, testSetup: record<account: record, additionalApks: list, directoriesToPull: list, dontAutograntPermissions: bool, environmentVariables: list, filesToPush: list, networkProfile: string, systrace: record>, testTimeout: string>, timestamp: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($test_matrix_id | is-empty) { error make --unspanned { msg: "path parameter 'testMatrixId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), test_matrix_id: (encode-path-segment $test_matrix_id)} | format pattern "/v1/projects/{project_id}/testMatrices/{test_matrix_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cancels unfinished test executions in a test matrix. This call returns immediately and cancellation proceeds asynchronously. If the matrix is already final, this operation will have no effect. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Test Matrix does not exist
#
# POST /v1/projects/{projectId}/testMatrices/{testMatrixId}:cancel
# operationId: testing.projects.testMatrices.cancel
export def "testing-projects-test-matrices-cancel" [
  project_id: string
  test_matrix_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
]: nothing -> oneof<record<testState: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($test_matrix_id | is-empty) { error make --unspanned { msg: "path parameter 'testMatrixId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), test_matrix_id: (encode-path-segment $test_matrix_id)} | format pattern "/v1/projects/{project_id}/testMatrices/{test_matrix_id}:cancel") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Gets the catalog of supported test environments. May return any of the following canonical error codes: - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the environment type does not exist - INTERNAL - if an internal error occurred
#
# GET /v1/testEnvironmentCatalog/{environmentType}
# operationId: testing.testEnvironmentCatalog.get
export def "testing-test-environment-catalog-get" [
  environment_type: string@environment-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
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
  --project-id: string # For authorization, the cloud project requesting the TestEnvironmentCatalog.
]: nothing -> oneof<record<androidDeviceCatalog: record<models: list<record>, runtimeConfiguration: record<locales: list, orientations: list>, versions: list<record>>, deviceIpBlockCatalog: record<ipBlocks: list<record>>, iosDeviceCatalog: record<models: list<record>, runtimeConfiguration: record<locales: list, orientations: list>, versions: list<record>, xcodeVersions: list<record>>, networkConfigurationCatalog: record<configurations: list<record>>, softwareCatalog: record<androidxOrchestratorVersion: string, orchestratorVersion: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($environment_type | is-empty) { error make --unspanned { msg: "path parameter 'environmentType' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_type: (encode-path-segment $environment_type)} | format pattern "/v1/testEnvironmentCatalog/{environment_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
