# Auto-generated client for Cloud Testing API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/testing/v1/openapi.json
# Auth: --token flag or $env.CLOUD_TESTING_API_TOKEN

const BASE_URL = "https://testing.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_TESTING_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://testing.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def invalidMatrixDetails-completer [] { ["BUILT_FOR_IOS_SIMULATOR" "DETAILS_UNAVAILABLE" "DEVICE_ADMIN_RECEIVER" "FORBIDDEN_PERMISSIONS" "INSTRUMENTATION_ORCHESTRATOR_INCOMPATIBLE" "INVALID_APK_PREVIEW_SDK" "INVALID_DIRECTIVE_ACTION" "INVALID_INPUT_APK" "INVALID_MATRIX_DETAILS_UNSPECIFIED" "INVALID_PACKAGE_NAME" "INVALID_RESOURCE_NAME" "INVALID_ROBO_DIRECTIVES" "MALFORMED_APK" "MALFORMED_APP_BUNDLE" "MALFORMED_IPA" "MALFORMED_TEST_APK" "MALFORMED_XC_TEST_ZIP" "MATRIX_TOO_LARGE" "MISSING_URL_SCHEME" "NO_CODE_APK" "NO_INSTRUMENTATION" "NO_LAUNCHER_ACTIVITY" "NO_MANIFEST" "NO_PACKAGE_NAME" "NO_SIGNATURE" "NO_TESTS_IN_XC_TEST_ZIP" "NO_TEST_RUNNER_CLASS" "PLIST_CANNOT_BE_PARSED" "SCENARIO_LABEL_MALFORMED" "SCENARIO_LABEL_NOT_DECLARED" "SCENARIO_NOT_DECLARED" "SERVICE_NOT_ACTIVATED" "TEST_LOOP_INTENT_FILTER_NOT_FOUND" "TEST_NOT_APP_HOSTED" "TEST_ONLY_APK" "TEST_QUOTA_EXCEEDED" "TEST_SAME_AS_APP" "UNKNOWN_PERMISSION_ERROR" "USE_DESTINATION_ARTIFACTS"] }
def outcomeSummary-completer [] { ["FAILURE" "INCONCLUSIVE" "OUTCOME_SUMMARY_UNSPECIFIED" "SKIPPED" "SUCCESS"] }
def state-completer [] { ["CANCELLED" "ERROR" "FINISHED" "INCOMPATIBLE_ARCHITECTURE" "INCOMPATIBLE_ENVIRONMENT" "INVALID" "PENDING" "RUNNING" "TEST_STATE_UNSPECIFIED" "UNSUPPORTED_ENVIRONMENT" "VALIDATING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "application-detail-service-get-apk-details testingapplicationDetailServicegetApkDetails" } } | get name | first)
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
export def "application-detail-service-get-apk-details testingapplicationDetailServicegetApkDetails" [
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
  --gcsPath: string # A path to a file in Google Cloud Storage. Example: gs://build-app-1414623860166/app%40debug-unaligned.apk These paths are expected to be url encoded (percent encoding)
]: any -> record<apkDetail: record<apkManifest: record<applicationLabel: string, intentFilters: list, maxSdkVersion: int, metadata: list, minSdkVersion: int, packageName: string, targetSdkVersion: int, usesFeature: list, usesPermission: list, versionCode: string, versionName: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/applicationDetailService/getApkDetails" $qp)
  let body = {gcsPath: $gcsPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "projects-test-matrices testingprojectstestMatricescreate" [
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
  --requestId: string # A string id used to detect duplicated requests. Ids are automatically scoped to a project, so users should ensure the ID is unique per-project. A UUID is recommended. Optional, but strongly recommended.
  --clientInfo: record # Information about the client which invoked the test. — shape: {clientInfoDetails?: list, name?: string}
  --environmentMatrix: record # The matrix of environments in which the test is to be executed. — shape: {androidDeviceList?: record, androidMatrix?: record, iosDeviceList?: record}
  --failFast: oneof<nothing, bool> # If true, only a single attempt at most will be made to run each execution/shard in the matrix. Flaky test attempts are not affected. Normally, 2 or more attempts are made if a potential infrastructure issue is detected. This feature is for latency sensitive workloads. The incidence of execution failures may be significantly greater for fail-fast matrices and support is more limited because of that expectation.
  --flakyTestAttempts: int # The number of times a TestExecution should be re-attempted if one or more of its test cases fail for any reason. The maximum number of reruns allowed is 10. Default is 0, which implies no reruns. (format: int32)
  --invalidMatrixDetails: string@invalidMatrixDetails-completer # Output only. Describes why the matrix is considered invalid. Only useful for matrices in the INVALID state.
  --outcomeSummary: string@outcomeSummary-completer # Output Only. The overall outcome of the test. Only set when the test matrix state is FINISHED.
  --body-projectId: string # The cloud project that owns the test matrix.
  --resultStorage: record # Locations where the results of running the test are stored. — shape: {googleCloudStorage?: record, resultsUrl?: string, toolResultsExecution?: record, toolResultsHistory?: record}
  --state: string@state-completer # Output only. Indicates the current progress of the test matrix.
  --testExecutions: list # Output only. The list of test executions that the service creates for this matrix. — item shape: {environment?: record, id?: string, matrixId?: string, projectId?: string, shard?: record, state?: "TEST_STATE_UNSPECIFIED"|"VALIDATING"|"PENDING"|"RUNNING"|"FINISHED"|"ERROR"|"UNSUPPORTED_ENVIRONMENT"|"INCOMPATIBLE_ENVIRONMENT"|"INCOMPATIBLE_ARCHITECTURE"|"CANCELLED"|"INVALID", testDetails?: record, testSpecification?: record, timestamp?: string, toolResultsStep?: record}
  --testMatrixId: string # Output only. Unique id set by the service.
  --testSpecification: record # A description of how to run the test. — shape: {androidInstrumentationTest?: record, androidRoboTest?: record, androidTestLoop?: record, disablePerformanceMetrics?: bool, disableVideoRecording?: bool, iosTestLoop?: record, iosTestSetup?: record, iosXcTest?: record, testSetup?: record, testTimeout?: string}
  --timestamp: string # Output only. The time this test matrix was initially created. (format: google-datetime)
]: any -> record<clientInfo: record<clientInfoDetails: list<record>, name: string>, environmentMatrix: record<androidDeviceList: record<androidDevices: list>, androidMatrix: record<androidModelIds: list, androidVersionIds: list, locales: list, orientations: list>, iosDeviceList: record<iosDevices: list>>, failFast: bool, flakyTestAttempts: int, invalidMatrixDetails: string, outcomeSummary: string, projectId: string, resultStorage: record<googleCloudStorage: record<gcsPath: string>, resultsUrl: string, toolResultsExecution: record<executionId: string, historyId: string, projectId: string>, toolResultsHistory: record<historyId: string, projectId: string>>, state: string, testExecutions: table<environment: record, id: string, matrixId: string, projectId: string, shard: record, state: string, testDetails: record, testSpecification: record, timestamp: string, toolResultsStep: record>, testMatrixId: string, testSpecification: record<androidInstrumentationTest: record<appApk: record, appBundle: record, appPackageId: string, orchestratorOption: string, shardingOption: record, testApk: record, testPackageId: string, testRunnerClass: string, testTargets: list>, androidRoboTest: record<appApk: record, appBundle: record, appInitialActivity: string, appPackageId: string, maxDepth: int, maxSteps: int, roboDirectives: list, roboMode: string, roboScript: record, startingIntents: list>, androidTestLoop: record<appApk: record, appBundle: record, appPackageId: string, scenarioLabels: list, scenarios: list>, disablePerformanceMetrics: bool, disableVideoRecording: bool, iosTestLoop: record<appBundleId: string, appIpa: record, scenarios: list>, iosTestSetup: record<additionalIpas: list, networkProfile: string, pullDirectories: list, pushFiles: list>, iosXcTest: record<appBundleId: string, testSpecialEntitlements: bool, testsZip: record, xcodeVersion: string, xctestrun: record>, testSetup: record<account: record, additionalApks: list, directoriesToPull: list, dontAutograntPermissions: bool, environmentVariables: list, filesToPush: list, networkProfile: string, systrace: record>, testTimeout: string>, timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "requestId" $requestId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/testMatrices" $qp)
  let body = {clientInfo: $clientInfo, environmentMatrix: $environmentMatrix, failFast: $failFast, flakyTestAttempts: $flakyTestAttempts, invalidMatrixDetails: $invalidMatrixDetails, outcomeSummary: $outcomeSummary, projectId: $body_projectId, resultStorage: $resultStorage, state: $state, testExecutions: $testExecutions, testMatrixId: $testMatrixId, testSpecification: $testSpecification, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Checks the status of a test matrix and the executions once they are created. The test matrix will contain the list of test executions to run if and only if the resultStorage.toolResultsExecution fields have been populated. Note: Flaky test executions may still be added to the matrix at a later stage. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Test Matrix does not exist
#
# GET /v1/projects/{projectId}/testMatrices/{testMatrixId}
# operationId: testing.projects.testMatrices.get
export def "projects-test-matrices testingprojectstestMatricesget" [
  projectId: string
  testMatrixId: string
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
]: nothing -> record<clientInfo: record<clientInfoDetails: list<record>, name: string>, environmentMatrix: record<androidDeviceList: record<androidDevices: list>, androidMatrix: record<androidModelIds: list, androidVersionIds: list, locales: list, orientations: list>, iosDeviceList: record<iosDevices: list>>, failFast: bool, flakyTestAttempts: int, invalidMatrixDetails: string, outcomeSummary: string, projectId: string, resultStorage: record<googleCloudStorage: record<gcsPath: string>, resultsUrl: string, toolResultsExecution: record<executionId: string, historyId: string, projectId: string>, toolResultsHistory: record<historyId: string, projectId: string>>, state: string, testExecutions: table<environment: record, id: string, matrixId: string, projectId: string, shard: record, state: string, testDetails: record, testSpecification: record, timestamp: string, toolResultsStep: record>, testMatrixId: string, testSpecification: record<androidInstrumentationTest: record<appApk: record, appBundle: record, appPackageId: string, orchestratorOption: string, shardingOption: record, testApk: record, testPackageId: string, testRunnerClass: string, testTargets: list>, androidRoboTest: record<appApk: record, appBundle: record, appInitialActivity: string, appPackageId: string, maxDepth: int, maxSteps: int, roboDirectives: list, roboMode: string, roboScript: record, startingIntents: list>, androidTestLoop: record<appApk: record, appBundle: record, appPackageId: string, scenarioLabels: list, scenarios: list>, disablePerformanceMetrics: bool, disableVideoRecording: bool, iosTestLoop: record<appBundleId: string, appIpa: record, scenarios: list>, iosTestSetup: record<additionalIpas: list, networkProfile: string, pullDirectories: list, pushFiles: list>, iosXcTest: record<appBundleId: string, testSpecialEntitlements: bool, testsZip: record, xcodeVersion: string, xctestrun: record>, testSetup: record<account: record, additionalApks: list, directoriesToPull: list, dontAutograntPermissions: bool, environmentVariables: list, filesToPush: list, networkProfile: string, systrace: record>, testTimeout: string>, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/testMatrices/($testMatrixId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancels unfinished test executions in a test matrix. This call returns immediately and cancellation proceeds asynchronously. If the matrix is already final, this operation will have no effect. May return any of the following canonical error codes: - PERMISSION_DENIED - if the user is not authorized to read project - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the Test Matrix does not exist
#
# POST /v1/projects/{projectId}/testMatrices/{testMatrixId}:cancel
# operationId: testing.projects.testMatrices.cancel
export def "projects-test-matrices testingprojectstestMatricescancel" [
  projectId: string
  testMatrixId: string
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
]: nothing -> record<testState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/projects/($projectId)/testMatrices/($testMatrixId):cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the catalog of supported test environments. May return any of the following canonical error codes: - INVALID_ARGUMENT - if the request is malformed - NOT_FOUND - if the environment type does not exist - INTERNAL - if an internal error occurred
#
# GET /v1/testEnvironmentCatalog/{environmentType}
# operationId: testing.testEnvironmentCatalog.get
export def "test-environment-catalog testingtestEnvironmentCatalogget" [
  environmentType: string
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
  --projectId: string # For authorization, the cloud project requesting the TestEnvironmentCatalog.
]: nothing -> record<androidDeviceCatalog: record<models: list<record>, runtimeConfiguration: record<locales: list, orientations: list>, versions: list<record>>, deviceIpBlockCatalog: record<ipBlocks: list<record>>, iosDeviceCatalog: record<models: list<record>, runtimeConfiguration: record<locales: list, orientations: list>, versions: list<record>, xcodeVersions: list<record>>, networkConfigurationCatalog: record<configurations: list<record>>, softwareCatalog: record<androidxOrchestratorVersion: string, orchestratorVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "projectId" $projectId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/testEnvironmentCatalog/($environmentType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
