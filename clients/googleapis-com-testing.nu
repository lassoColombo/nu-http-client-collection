# Auto-generated client for Cloud Testing API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/testing/v1/openapi.json
# Auth: --token flag or $env.CLOUD_TESTING_API_TOKEN

const BASE_URL = "https://testing.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_TESTING_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://testing.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def invalid-matrix-details-completer [] { ["BUILT_FOR_IOS_SIMULATOR" "DETAILS_UNAVAILABLE" "DEVICE_ADMIN_RECEIVER" "FORBIDDEN_PERMISSIONS" "INSTRUMENTATION_ORCHESTRATOR_INCOMPATIBLE" "INVALID_APK_PREVIEW_SDK" "INVALID_DIRECTIVE_ACTION" "INVALID_INPUT_APK" "INVALID_MATRIX_DETAILS_UNSPECIFIED" "INVALID_PACKAGE_NAME" "INVALID_RESOURCE_NAME" "INVALID_ROBO_DIRECTIVES" "MALFORMED_APK" "MALFORMED_APP_BUNDLE" "MALFORMED_IPA" "MALFORMED_TEST_APK" "MALFORMED_XC_TEST_ZIP" "MATRIX_TOO_LARGE" "MISSING_URL_SCHEME" "NO_CODE_APK" "NO_INSTRUMENTATION" "NO_LAUNCHER_ACTIVITY" "NO_MANIFEST" "NO_PACKAGE_NAME" "NO_SIGNATURE" "NO_TESTS_IN_XC_TEST_ZIP" "NO_TEST_RUNNER_CLASS" "PLIST_CANNOT_BE_PARSED" "SCENARIO_LABEL_MALFORMED" "SCENARIO_LABEL_NOT_DECLARED" "SCENARIO_NOT_DECLARED" "SERVICE_NOT_ACTIVATED" "TEST_LOOP_INTENT_FILTER_NOT_FOUND" "TEST_NOT_APP_HOSTED" "TEST_ONLY_APK" "TEST_QUOTA_EXCEEDED" "TEST_SAME_AS_APP" "UNKNOWN_PERMISSION_ERROR" "USE_DESTINATION_ARTIFACTS"] }
def outcome-summary-completer [] { ["FAILURE" "INCONCLUSIVE" "OUTCOME_SUMMARY_UNSPECIFIED" "SKIPPED" "SUCCESS"] }
def state-completer [] { ["CANCELLED" "ERROR" "FINISHED" "INCOMPATIBLE_ARCHITECTURE" "INCOMPATIBLE_ENVIRONMENT" "INVALID" "PENDING" "RUNNING" "TEST_STATE_UNSPECIFIED" "UNSUPPORTED_ENVIRONMENT" "VALIDATING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "application-detail-service-get-apk-details get" } } | get name | first)
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

# Gets the details of an Android application APK.
#
# POST /v1/applicationDetailService/getApkDetails
# operationId: testing.applicationDetailService.getApkDetails
export def "application-detail-service-get-apk-details get" [
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
]: any -> record<apkDetail: record<apkManifest: record<applicationLabel: string, intentFilters: list, maxSdkVersion: int, metadata: list, minSdkVersion: int, packageName: string, targetSdkVersion: int, usesFeature: list, usesPermission: list, versionCode: string, versionName: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/applicationDetailService/getApkDetails" $qp)
  let req_body = {"gcsPath": $gcs_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Creates and runs a matrix of tests according to the given specifications. Unsupported environments will be returned in the state UNSUPPORTED. A test matrix is limited to use at most 2000 devices in parallel. The returned matrix will not yet contain the executions that will be created for this matrix. That happens later on and will require a call to GetTestMatrix. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to write to project - INVALID_ARGUMENT - if the request is malformed or if the matrix tries to use too many simultaneous devices.
#
# POST /v1/projects/{projectId}/testMatrices
# operationId: testing.projects.testMatrices.create
# --clientInfo shape: {clientInfoDetails?: list, name?: string}
# --environmentMatrix shape: {androidDeviceList?: record, androidMatrix?: record, iosDeviceList?: record}
# --resultStorage shape: {googleCloudStorage?: record, resultsUrl?: string, toolResultsExecution?: record, toolResultsHistory?: record}
# --testExecutions item shape: {environment?: record, id?: string, matrixId?: string, projectId?: string, shard?: record, state?: "TEST_STATE_UNSPECIFIED"|"VALIDATING"|"PENDING"|"RUNNING"|"FINISHED"|"ERROR"|"UNSUPPORTED_ENVIRONMENT"|"INCOMPATIBLE_ENVIRONMENT"|"INCOMPATIBLE_ARCHITECTURE"|"CANCELLED"|"INVALID", testDetails?: record, testSpecification?: record, timestamp?: string, toolResultsStep?: record}
# --testSpecification shape: {androidInstrumentationTest?: record, androidRoboTest?: record, androidTestLoop?: record, disablePerformanceMetrics?: bool, disableVideoRecording?: bool, iosTestLoop?: record, iosTestSetup?: record, iosXcTest?: record, testSetup?: record, testTimeout?: string}
export def "projects-test-matrices create" [
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
  --body-project-id: string # The cloud project that owns the test matrix.
  --result-storage: record # Locations where the results of running the test are stored. — shape: {googleCloudStorage?: record, resultsUrl?: string, toolResultsExecution?: record, toolResultsHistory?: record}
  --state: string@state-completer # Output only. Indicates the current progress of the test matrix.
  --test-executions: list # Output only. The list of test executions that the service creates for this matrix. — item shape: {environment?: record, id?: string, matrixId?: string, projectId?: string, shard?: record, state?: "TEST_STATE_UNSPECIFIED"|"VALIDATING"|"PENDING"|"RUNNING"|"FINISHED"|"ERROR"|"UNSUPPORTED_ENVIRONMENT"|"INCOMPATIBLE_ENVIRONMENT"|"INCOMPATIBLE_ARCHITECTURE"|"CANCELLED"|"INVALID", testDetails?: record, testSpecification?: record, timestamp?: string, toolResultsStep?: record}
  --test-matrix-id: string # Output only. Unique id set by the service.
  --test-specification: record # A description of how to run the test. — shape: {androidInstrumentationTest?: record, androidRoboTest?: record, androidTestLoop?: record, disablePerformanceMetrics?: bool, disableVideoRecording?: bool, iosTestLoop?: record, iosTestSetup?: record, iosXcTest?: record, testSetup?: record, testTimeout?: string}
  --timestamp: string # Output only. The time this test matrix was initially created. (format: google-datetime)
]: any -> record<clientInfo: record<clientInfoDetails: list<record>, name: string>, environmentMatrix: record<androidDeviceList: record<androidDevices: list>, androidMatrix: record<androidModelIds: list, androidVersionIds: list, locales: list, orientations: list>, iosDeviceList: record<iosDevices: list>>, failFast: bool, flakyTestAttempts: int, invalidMatrixDetails: string, outcomeSummary: string, projectId: string, resultStorage: record<googleCloudStorage: record<gcsPath: string>, resultsUrl: string, toolResultsExecution: record<executionId: string, historyId: string, projectId: string>, toolResultsHistory: record<historyId: string, projectId: string>>, state: string, testExecutions: table<environment: record, id: string, matrixId: string, projectId: string, shard: record, state: string, testDetails: record, testSpecification: record, timestamp: string, toolResultsStep: record>, testMatrixId: string, testSpecification: record<androidInstrumentationTest: record<appApk: record, appBundle: record, appPackageId: string, orchestratorOption: string, shardingOption: record, testApk: record, testPackageId: string, testRunnerClass: string, testTargets: list>, androidRoboTest: record<appApk: record, appBundle: record, appInitialActivity: string, appPackageId: string, maxDepth: int, maxSteps: int, roboDirectives: list, roboMode: string, roboScript: record, startingIntents: list>, androidTestLoop: record<appApk: record, appBundle: record, appPackageId: string, scenarioLabels: list, scenarios: list>, disablePerformanceMetrics: bool, disableVideoRecording: bool, iosTestLoop: record<appBundleId: string, appIpa: record, scenarios: list>, iosTestSetup: record<additionalIpas: list, networkProfile: string, pullDirectories: list, pushFiles: list>, iosXcTest: record<appBundleId: string, testSpecialEntitlements: bool, testsZip: record, xcodeVersion: string, xctestrun: record>, testSetup: record<account: record, additionalApks: list, directoriesToPull: list, dontAutograntPermissions: bool, environmentVariables: list, filesToPush: list, networkProfile: string, systrace: record>, testTimeout: string>, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v1/projects/{project_id}/testMatrices") $qp)
  let req_body = {"clientInfo": $client_info, "environmentMatrix": $environment_matrix, "failFast": $fail_fast, "flakyTestAttempts": $flaky_test_attempts, "invalidMatrixDetails": $invalid_matrix_details, "outcomeSummary": $outcome_summary, "projectId": $body_project_id, "resultStorage": $result_storage, "state": $state, "testExecutions": $test_executions, "testMatrixId": $test_matrix_id, "testSpecification": $test_specification, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "requestId": $request_id} | compact), body: $req_body}
}

# Checks the status of a test matrix and the executions once they are created. The test matrix will contain the list of test executions to run if and only if the resultStorage.toolResultsExecution fields have been populated. Note: Flaky test executions may still be added to the matrix at a later stage. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Test Matrix does not exist
#
# GET /v1/projects/{projectId}/testMatrices/{testMatrixId}
# operationId: testing.projects.testMatrices.get
export def "projects-test-matrices get" [
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
]: nothing -> record<clientInfo: record<clientInfoDetails: list<record>, name: string>, environmentMatrix: record<androidDeviceList: record<androidDevices: list>, androidMatrix: record<androidModelIds: list, androidVersionIds: list, locales: list, orientations: list>, iosDeviceList: record<iosDevices: list>>, failFast: bool, flakyTestAttempts: int, invalidMatrixDetails: string, outcomeSummary: string, projectId: string, resultStorage: record<googleCloudStorage: record<gcsPath: string>, resultsUrl: string, toolResultsExecution: record<executionId: string, historyId: string, projectId: string>, toolResultsHistory: record<historyId: string, projectId: string>>, state: string, testExecutions: table<environment: record, id: string, matrixId: string, projectId: string, shard: record, state: string, testDetails: record, testSpecification: record, timestamp: string, toolResultsStep: record>, testMatrixId: string, testSpecification: record<androidInstrumentationTest: record<appApk: record, appBundle: record, appPackageId: string, orchestratorOption: string, shardingOption: record, testApk: record, testPackageId: string, testRunnerClass: string, testTargets: list>, androidRoboTest: record<appApk: record, appBundle: record, appInitialActivity: string, appPackageId: string, maxDepth: int, maxSteps: int, roboDirectives: list, roboMode: string, roboScript: record, startingIntents: list>, androidTestLoop: record<appApk: record, appBundle: record, appPackageId: string, scenarioLabels: list, scenarios: list>, disablePerformanceMetrics: bool, disableVideoRecording: bool, iosTestLoop: record<appBundleId: string, appIpa: record, scenarios: list>, iosTestSetup: record<additionalIpas: list, networkProfile: string, pullDirectories: list, pushFiles: list>, iosXcTest: record<appBundleId: string, testSpecialEntitlements: bool, testsZip: record, xcodeVersion: string, xctestrun: record>, testSetup: record<account: record, additionalApks: list, directoriesToPull: list, dontAutograntPermissions: bool, environmentVariables: list, filesToPush: list, networkProfile: string, systrace: record>, testTimeout: string>, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($test_matrix_id | is-empty) { error make --unspanned { msg: "path parameter 'testMatrixId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), test_matrix_id: (encode-path-segment $test_matrix_id)} | format pattern "/v1/projects/{project_id}/testMatrices/{test_matrix_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Cancels unfinished test executions in a test matrix. This call returns immediately and cancellation proceeds asynchronously. If the matrix is already final, this operation will have no effect. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Test Matrix does not exist
#
# POST /v1/projects/{projectId}/testMatrices/{testMatrixId}:cancel
# operationId: testing.projects.testMatrices.cancel
export def "projects-test-matrices cancel" [
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
]: nothing -> record<testState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($test_matrix_id | is-empty) { error make --unspanned { msg: "path parameter 'testMatrixId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), test_matrix_id: (encode-path-segment $test_matrix_id)} | format pattern "/v1/projects/{project_id}/testMatrices/{test_matrix_id}:cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Gets the catalog of supported test environments. May return any of the following canonical error codes: - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the environment type does not exist - INTERNAL - if an internal error occurred
#
# GET /v1/testEnvironmentCatalog/{environmentType}
# operationId: testing.testEnvironmentCatalog.get
export def "test-environment-catalog get" [
  environment_type: string
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
]: nothing -> record<androidDeviceCatalog: record<models: list<record>, runtimeConfiguration: record<locales: list, orientations: list>, versions: list<record>>, deviceIpBlockCatalog: record<ipBlocks: list<record>>, iosDeviceCatalog: record<models: list<record>, runtimeConfiguration: record<locales: list, orientations: list>, versions: list<record>, xcodeVersions: list<record>>, networkConfigurationCatalog: record<configurations: list<record>>, softwareCatalog: record<androidxOrchestratorVersion: string, orchestratorVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($environment_type | is-empty) { error make --unspanned { msg: "path parameter 'environmentType' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "projectId" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_type: (encode-path-segment $environment_type)} | format pattern "/v1/testEnvironmentCatalog/{environment_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "projectId": $project_id} | compact), body: null}
}
