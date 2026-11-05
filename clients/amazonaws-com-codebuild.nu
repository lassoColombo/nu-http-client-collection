# Auto-generated client for AWS CodeBuild v2016-10-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codebuild/2016-10-06/openapi.json
# Auth: --token flag or $env.AWS_CODEBUILD_TOKEN

const BASE_URL = "http://codebuild.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_CODEBUILD_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://codebuild.us-east-1.amazonaws.com" "http://codebuild.us-east-2.amazonaws.com" "http://codebuild.us-west-1.amazonaws.com" "http://codebuild.us-west-2.amazonaws.com" "http://codebuild.us-gov-west-1.amazonaws.com" "http://codebuild.us-gov-east-1.amazonaws.com" "http://codebuild.ca-central-1.amazonaws.com" "http://codebuild.eu-north-1.amazonaws.com" "http://codebuild.eu-west-1.amazonaws.com" "http://codebuild.eu-west-2.amazonaws.com" "http://codebuild.eu-west-3.amazonaws.com" "http://codebuild.eu-central-1.amazonaws.com" "http://codebuild.eu-south-1.amazonaws.com" "http://codebuild.af-south-1.amazonaws.com" "http://codebuild.ap-northeast-1.amazonaws.com" "http://codebuild.ap-northeast-2.amazonaws.com" "http://codebuild.ap-northeast-3.amazonaws.com" "http://codebuild.ap-southeast-1.amazonaws.com" "http://codebuild.ap-southeast-2.amazonaws.com" "http://codebuild.ap-east-1.amazonaws.com" "http://codebuild.ap-south-1.amazonaws.com" "http://codebuild.sa-east-1.amazonaws.com" "http://codebuild.me-south-1.amazonaws.com" "https://codebuild.us-east-1.amazonaws.com" "https://codebuild.us-east-2.amazonaws.com" "https://codebuild.us-west-1.amazonaws.com" "https://codebuild.us-west-2.amazonaws.com" "https://codebuild.us-gov-west-1.amazonaws.com" "https://codebuild.us-gov-east-1.amazonaws.com" "https://codebuild.ca-central-1.amazonaws.com" "https://codebuild.eu-north-1.amazonaws.com" "https://codebuild.eu-west-1.amazonaws.com" "https://codebuild.eu-west-2.amazonaws.com" "https://codebuild.eu-west-3.amazonaws.com" "https://codebuild.eu-central-1.amazonaws.com" "https://codebuild.eu-south-1.amazonaws.com" "https://codebuild.af-south-1.amazonaws.com" "https://codebuild.ap-northeast-1.amazonaws.com" "https://codebuild.ap-northeast-2.amazonaws.com" "https://codebuild.ap-northeast-3.amazonaws.com" "https://codebuild.ap-southeast-1.amazonaws.com" "https://codebuild.ap-southeast-2.amazonaws.com" "https://codebuild.ap-east-1.amazonaws.com" "https://codebuild.ap-south-1.amazonaws.com" "https://codebuild.sa-east-1.amazonaws.com" "https://codebuild.me-south-1.amazonaws.com" "http://codebuild.cn-north-1.amazonaws.com.cn" "http://codebuild.cn-northwest-1.amazonaws.com.cn" "https://codebuild.cn-north-1.amazonaws.com.cn" "https://codebuild.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["CodeBuild_20161006.BatchDeleteBuilds"] }
def x-amz-target-completer-1 [] { ["CodeBuild_20161006.BatchGetBuildBatches"] }
def x-amz-target-completer-2 [] { ["CodeBuild_20161006.BatchGetBuilds"] }
def x-amz-target-completer-3 [] { ["CodeBuild_20161006.BatchGetProjects"] }
def x-amz-target-completer-4 [] { ["CodeBuild_20161006.BatchGetReportGroups"] }
def x-amz-target-completer-5 [] { ["CodeBuild_20161006.BatchGetReports"] }
def x-amz-target-completer-6 [] { ["CodeBuild_20161006.CreateProject"] }
def type-completer [] { ["CODE_COVERAGE" "TEST"] }
def x-amz-target-completer-7 [] { ["CodeBuild_20161006.CreateReportGroup"] }
def build-type-completer [] { ["BUILD" "BUILD_BATCH"] }
def x-amz-target-completer-8 [] { ["CodeBuild_20161006.CreateWebhook"] }
def x-amz-target-completer-9 [] { ["CodeBuild_20161006.DeleteBuildBatch"] }
def x-amz-target-completer-10 [] { ["CodeBuild_20161006.DeleteProject"] }
def x-amz-target-completer-11 [] { ["CodeBuild_20161006.DeleteReport"] }
def x-amz-target-completer-12 [] { ["CodeBuild_20161006.DeleteReportGroup"] }
def x-amz-target-completer-13 [] { ["CodeBuild_20161006.DeleteResourcePolicy"] }
def x-amz-target-completer-14 [] { ["CodeBuild_20161006.DeleteSourceCredentials"] }
def x-amz-target-completer-15 [] { ["CodeBuild_20161006.DeleteWebhook"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def sort-by-completer [] { ["FILE_PATH" "LINE_COVERAGE_PERCENTAGE"] }
def x-amz-target-completer-16 [] { ["CodeBuild_20161006.DescribeCodeCoverages"] }
def x-amz-target-completer-17 [] { ["CodeBuild_20161006.DescribeTestCases"] }
def trend-field-completer [] { ["BRANCHES_COVERED" "BRANCHES_MISSED" "BRANCH_COVERAGE" "DURATION" "LINES_COVERED" "LINES_MISSED" "LINE_COVERAGE" "PASS_RATE" "TOTAL"] }
def x-amz-target-completer-18 [] { ["CodeBuild_20161006.GetReportGroupTrend"] }
def x-amz-target-completer-19 [] { ["CodeBuild_20161006.GetResourcePolicy"] }
def server-type-completer [] { ["BITBUCKET" "GITHUB" "GITHUB_ENTERPRISE"] }
def auth-type-completer [] { ["BASIC_AUTH" "OAUTH" "PERSONAL_ACCESS_TOKEN"] }
def x-amz-target-completer-20 [] { ["CodeBuild_20161006.ImportSourceCredentials"] }
def x-amz-target-completer-21 [] { ["CodeBuild_20161006.InvalidateProjectCache"] }
def x-amz-target-completer-22 [] { ["CodeBuild_20161006.ListBuildBatches"] }
def x-amz-target-completer-23 [] { ["CodeBuild_20161006.ListBuildBatchesForProject"] }
def x-amz-target-completer-24 [] { ["CodeBuild_20161006.ListBuilds"] }
def x-amz-target-completer-25 [] { ["CodeBuild_20161006.ListBuildsForProject"] }
def x-amz-target-completer-26 [] { ["CodeBuild_20161006.ListCuratedEnvironmentImages"] }
def sort-by-completer-1 [] { ["CREATED_TIME" "LAST_MODIFIED_TIME" "NAME"] }
def x-amz-target-completer-27 [] { ["CodeBuild_20161006.ListProjects"] }
def x-amz-target-completer-28 [] { ["CodeBuild_20161006.ListReportGroups"] }
def x-amz-target-completer-29 [] { ["CodeBuild_20161006.ListReports"] }
def x-amz-target-completer-30 [] { ["CodeBuild_20161006.ListReportsForReportGroup"] }
def sort-by-completer-2 [] { ["ARN" "MODIFIED_TIME"] }
def x-amz-target-completer-31 [] { ["CodeBuild_20161006.ListSharedProjects"] }
def x-amz-target-completer-32 [] { ["CodeBuild_20161006.ListSharedReportGroups"] }
def x-amz-target-completer-33 [] { ["CodeBuild_20161006.ListSourceCredentials"] }
def x-amz-target-completer-34 [] { ["CodeBuild_20161006.PutResourcePolicy"] }
def x-amz-target-completer-35 [] { ["CodeBuild_20161006.RetryBuild"] }
def retry-type-completer [] { ["RETRY_ALL_BUILDS" "RETRY_FAILED_BUILDS"] }
def x-amz-target-completer-36 [] { ["CodeBuild_20161006.RetryBuildBatch"] }
def source-type-override-completer [] { ["BITBUCKET" "CODECOMMIT" "CODEPIPELINE" "GITHUB" "GITHUB_ENTERPRISE" "NO_SOURCE" "S3"] }
def environment-type-override-completer [] { ["ARM_CONTAINER" "LINUX_CONTAINER" "LINUX_GPU_CONTAINER" "WINDOWS_CONTAINER" "WINDOWS_SERVER_2019_CONTAINER"] }
def compute-type-override-completer [] { ["BUILD_GENERAL1_2XLARGE" "BUILD_GENERAL1_LARGE" "BUILD_GENERAL1_MEDIUM" "BUILD_GENERAL1_SMALL"] }
def image-pull-credentials-type-override-completer [] { ["CODEBUILD" "SERVICE_ROLE"] }
def x-amz-target-completer-37 [] { ["CodeBuild_20161006.StartBuild"] }
def x-amz-target-completer-38 [] { ["CodeBuild_20161006.StartBuildBatch"] }
def x-amz-target-completer-39 [] { ["CodeBuild_20161006.StopBuild"] }
def x-amz-target-completer-40 [] { ["CodeBuild_20161006.StopBuildBatch"] }
def x-amz-target-completer-41 [] { ["CodeBuild_20161006.UpdateProject"] }
def project-visibility-completer [] { ["PRIVATE" "PUBLIC_READ"] }
def x-amz-target-completer-42 [] { ["CodeBuild_20161006.UpdateProjectVisibility"] }
def x-amz-target-completer-43 [] { ["CodeBuild_20161006.UpdateReportGroup"] }
def x-amz-target-completer-44 [] { ["CodeBuild_20161006.UpdateWebhook"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-delete-builds" "batch-get-build-batches" "batch-get-builds" "batch-get-projects" "batch-get-report-groups" "batch-get-reports" "create-project" "create-report-group" "create-webhook" "delete-build-batch" "delete-project" "delete-report" "delete-report-group" "delete-resource-policy" "delete-source-credentials" "delete-webhook" "describe-code-coverages" "describe-test-cases" "get-report-group-trend" "get-resource-policy" "import-source-credentials" "invalidate-project-cache" "list-build-batches" "list-build-batches-for-project" "list-builds" "list-builds-for-project" "list-curated-environment-images" "list-projects" "list-report-groups" "list-reports" "list-reports-for-report-group" "list-shared-projects" "list-shared-report-groups" "list-source-credentials" "put-resource-policy" "retry-build" "retry-build-batch" "start-build" "start-build-batch" "stop-build" "stop-build-batch" "update-project" "update-project-visibility" "update-report-group" "update-webhook" "commands"] | sort) } | get name | first)
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

# Deletes one or more builds.
#
# POST /
# operationId: BatchDeleteBuilds
export def "batch-delete-builds" [
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
  --x-amz-target: string@x-amz-target-completer # required
  ids: list<string> # The IDs of the builds to delete.
]: any -> oneof<record<buildsDeleted: list<string>, buildsNotDeleted: table<id: string, statusCode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.BatchDeleteBuilds")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Retrieves information about one or more batch builds.
#
# POST /
# operationId: BatchGetBuildBatches
export def "batch-get-build-batches" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  ids: list<string> # An array that contains the batch build identifiers to retrieve.
]: any -> oneof<record<buildBatches: table<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list, source: record, secondarySources: list, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, logConfig: record, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list, buildBatchConfig: record, buildGroups: list, debugSessionEnabled: bool>, buildBatchesNotFound: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.BatchGetBuildBatches")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Gets information about one or more builds.
#
# POST /
# operationId: BatchGetBuilds
export def "batch-get-builds" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  ids: list<string> # The IDs of the builds.
]: any -> oneof<record<builds: table<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list, source: record, secondarySources: list, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, logs: record, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record, networkInterface: record, encryptionKey: string, exportedEnvironmentVariables: list, reportArns: list, fileSystemLocations: list, debugSession: record, buildBatchArn: string>, buildsNotFound: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.BatchGetBuilds")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Gets information about one or more build projects.
#
# POST /
# operationId: BatchGetProjects
export def "batch-get-projects" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  names: list<string> # The names or ARNs of the build projects. To get information about a project shared with your Amazon Web Services account, its ARN must be specified. You cannot specify a shared project using its name.
]: any -> oneof<record<projects: table<name: string, arn: string, description: string, source: record, secondarySources: list, sourceVersion: string, secondarySourceVersions: list, artifacts: record, secondaryArtifacts: list, cache: record, environment: record, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list, created: string, lastModified: string, webhook: record, vpcConfig: record, badge: record, logsConfig: record, fileSystemLocations: list, buildBatchConfig: record, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>, projectsNotFound: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.BatchGetProjects")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"names": $names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Returns an array of report groups.
#
# POST /
# operationId: BatchGetReportGroups
export def "batch-get-report-groups" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  report_group_arns: list<string> # An array of report group ARNs that identify the report groups to return.
]: any -> oneof<record<reportGroups: table<arn: string, name: string, type: string, exportConfig: record, created: string, lastModified: string, tags: list, status: string>, reportGroupsNotFound: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.BatchGetReportGroups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"reportGroupArns": $report_group_arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Returns an array of reports.
#
# POST /
# operationId: BatchGetReports
export def "batch-get-reports" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  report_arns: list<string> # An array of ARNs that identify the Report objects to return.
]: any -> oneof<record<reports: table<arn: string, type: string, name: string, reportGroupArn: string, executionId: string, status: string, created: string, expired: string, exportConfig: record, truncated: bool, testSummary: record, codeCoverageSummary: record>, reportsNotFound: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.BatchGetReports")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"reportArns": $report_arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Creates a build project.
#
# POST /
# operationId: CreateProject
export def "create-project" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  name: string # The name of the build project.
  --description: string # A description that makes the build project easy to identify.
  source: record # Information about the build input source code for the build project. — shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources: list # An array of ProjectSource objects. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --source-version: string # A version of the build input to be built for this project. If not specified, the latest version is used. If specified, it must be one of: For CodeCommit: the commit ID, branch, or Git tag to use. For GitHub: the commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Bitbucket: the commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Amazon S3: the version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the build level, then that version takes precedence over this sourceVersion (at the project level). For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --secondary-source-versions: list # An array of ProjectSourceVersion objects. If secondarySourceVersions is specified at the build level, then they take precedence over these secondarySourceVersions (at the project level). — item shape: {sourceIdentifier: string, sourceVersion: string}
  artifacts: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts: list # An array of ProjectArtifacts objects. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --cache: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  environment: record # Information about the build environment of the build project. — shape: {type: "WINDOWS_CONTAINER"|"LINUX_CONTAINER"|"LINUX_GPU_CONTAINER"|"ARM_CONTAINER"|"WINDOWS_SERVER_2019_CONTAINER", image: string, computeType: "BUILD_GENERAL1_SMALL"|"BUILD_GENERAL1_MEDIUM"|"BUILD_GENERAL1_LARGE"|"BUILD_GENERAL1_2XLARGE", environmentVariables?: list, privilegedMode?: bool, certificate?: string, registryCredential?: record, imagePullCredentialsType?: "CODEBUILD"|"SERVICE_ROLE"}
  service_role: string # The ARN of the IAM role that enables CodeBuild to interact with dependent Amazon Web Services services on behalf of the Amazon Web Services account.
  --timeout-in-minutes: int # How long, in minutes, from 5 to 480 (8 hours), for CodeBuild to wait before it times out any build that has not been marked as completed. The default is 60 minutes.
  --queued-timeout-in-minutes: int # The number of minutes a build is allowed to be queued before it times out.
  --encryption-key: string # The Key Management Service customer master key (CMK) to be used for encrypting the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --tags: list # A list of tag key and value pairs associated with this build project. These tags are available for use by Amazon Web Services services that support CodeBuild build project tags. — item shape: {key?: string, value?: string}
  --vpc-config: record # Information about the VPC configuration that CodeBuild accesses. — shape: {vpcId?: string, subnets?: list<string>, securityGroupIds?: list<string>}
  --badge-enabled: oneof<nothing, bool> # Set this to true to generate a publicly accessible URL for your project's build badge.
  --logs-config: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --file-system-locations: list # An array of ProjectFileSystemLocation objects for a CodeBuild build project. A ProjectFileSystemLocation object specifies the identifier, location, mountOptions, mountPoint, and type of a file system created using Amazon Elastic File System. — item shape: {type?: "EFS", location?: string, mountPoint?: string, identifier?: string, mountOptions?: string}
  --build-batch-config: record # Contains configuration information about a batch build project. — shape: {serviceRole?: string, combineArtifacts?: bool, restrictions?: record, timeoutInMins?: int, batchReportMode?: "REPORT_INDIVIDUAL_BUILDS"|"REPORT_AGGREGATED_BATCH"}
  --concurrent-build-limit: int # The maximum number of concurrent builds that are allowed for this project. New builds are only started if the current number of builds is less than or equal to this limit. If the current build count meets this limit, new builds are throttled and are not run.
]: any -> oneof<record<project: record<name: string, arn: string, description: string, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, sourceVersion: string, secondarySourceVersions: list<record>, artifacts: record<type: string, location: string, path: string, namespaceType: string, name: string, packaging: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list<record>, created: string, lastModified: string, webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list, buildType: string, lastModifiedSecret: string>, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, badge: record<badgeEnabled: bool, badgeRequestUrl: string>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.CreateProject")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "description": $description, "source": $source, "secondarySources": $secondary_sources, "sourceVersion": $source_version, "secondarySourceVersions": $secondary_source_versions, "artifacts": $artifacts, "secondaryArtifacts": $secondary_artifacts, "cache": $cache, "environment": $environment, "serviceRole": $service_role, "timeoutInMinutes": $timeout_in_minutes, "queuedTimeoutInMinutes": $queued_timeout_in_minutes, "encryptionKey": $encryption_key, "tags": $tags, "vpcConfig": $vpc_config, "badgeEnabled": $badge_enabled, "logsConfig": $logs_config, "fileSystemLocations": $file_system_locations, "buildBatchConfig": $build_batch_config, "concurrentBuildLimit": $concurrent_build_limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Creates a report group. A report group contains a collection of reports.
#
# POST /
# operationId: CreateReportGroup
export def "create-report-group" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  name: string # The name of the report group.
  type: string@type-completer # The type of report group.
  export_config: record # Information about the location where the run of a report is exported. — shape: {exportConfigType?: "S3"|"NO_EXPORT", s3Destination?: record}
  --tags: list # A list of tag key and value pairs associated with this report group. These tags are available for use by Amazon Web Services services that support CodeBuild report group tags. — item shape: {key?: string, value?: string}
]: any -> oneof<record<reportGroup: record<arn: string, name: string, type: string, exportConfig: record<exportConfigType: string, s3Destination: record>, created: string, lastModified: string, tags: list<record>, status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.CreateReportGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "type": $type, "exportConfig": $export_config, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables CodeBuild to start rebuilding the source code every time a code change is pushed to the repository. If you enable webhooks for an CodeBuild project, and the project is used as a build step in CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using CodePipeline, we recommend that you disable webhooks in CodeBuild. In the CodeBuild console, clear the Webhook box. For more information, see step 5 in Change a Build Project's Settings (https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console).
#
# POST /
# operationId: CreateWebhook
export def "create-webhook" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  project_name: string # The name of the CodeBuild project.
  --branch-filter: string # A regular expression used to determine which repository branches are built when a webhook is triggered. If the name of a branch matches the regular expression, then it is built. If branchFilter is empty, then all branches are built. It is recommended that you use filterGroups instead of branchFilter.
  --filter-groups: list # An array of arrays of WebhookFilter objects used to determine which webhooks are triggered. At least one WebhookFilter in the array must specify EVENT as its type. For a build to be triggered, at least one filter group in the filterGroups array must pass. For a filter group to pass, each of its filters must pass.
  --build-type: string@build-type-completer # Specifies the type of build this webhook will trigger.
]: any -> oneof<record<webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list<list>, buildType: string, lastModifiedSecret: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.CreateWebhook")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"projectName": $project_name, "branchFilter": $branch_filter, "filterGroups": $filter_groups, "buildType": $build_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Deletes a batch build.
#
# POST /
# operationId: DeleteBuildBatch
export def "delete-build-batch" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  id: string # The identifier of the batch build to delete.
]: any -> oneof<record<statusCode: string, buildsDeleted: list<string>, buildsNotDeleted: table<id: string, statusCode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DeleteBuildBatch")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Deletes a build project. When you delete a project, its builds are not deleted.
#
# POST /
# operationId: DeleteProject
export def "delete-project" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  name: string # The name of the build project.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DeleteProject")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Deletes a report.
#
# POST /
# operationId: DeleteReport
export def "delete-report" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  arn: string # The ARN of the report to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DeleteReport")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"arn": $arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Deletes a report group. Before you delete a report group, you must delete its reports.
#
# POST /
# operationId: DeleteReportGroup
export def "delete-report-group" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  arn: string # The ARN of the report group to delete.
  --delete-reports: oneof<nothing, bool> # If true, deletes any reports that belong to a report group before deleting the report group. If false, you must delete any reports in the report group. Use ListReportsForReportGroup (https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ListReportsForReportGroup.html) to get the reports in a report group. Use DeleteReport (https://docs.aws.amazon.com/codebuild/latest/APIReference/API_DeleteReport.html) to delete the reports. If you call DeleteReportGroup for a report group that contains one or more reports, an exception is thrown.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DeleteReportGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"arn": $arn, "deleteReports": $delete_reports} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Deletes a resource policy that is identified by its resource ARN.
#
# POST /
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  resource_arn: string # The ARN of the resource that is associated with the resource policy.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DeleteResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials.
#
# POST /
# operationId: DeleteSourceCredentials
export def "delete-source-credentials" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  arn: string # The Amazon Resource Name (ARN) of the token.
]: any -> oneof<record<arn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DeleteSourceCredentials")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"arn": $arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
#
# POST /
# operationId: DeleteWebhook
export def "delete-webhook" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  project_name: string # The name of the CodeBuild project.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DeleteWebhook")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"projectName": $project_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Retrieves one or more code coverage reports.
#
# POST /
# operationId: DescribeCodeCoverages
export def "describe-code-coverages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  report_arn: string # The ARN of the report for which test cases are returned.
  --next-token-body: string # The nextToken value returned from a previous call to DescribeCodeCoverages. This specifies the next item to return. To return the beginning of the list, exclude this parameter. (body field)
  --max-results-body: int # The maximum number of results to return. (body field)
  --sort-order: string@sort-order-completer # Specifies if the results are sorted in ascending or descending order.
  --sort-by: string@sort-by-completer # Specifies how the results are sorted. Possible values are: FILE_PATH The results are sorted by file path. LINE_COVERAGE_PERCENTAGE The results are sorted by the percentage of lines that are covered.
  --min-line-coverage-percentage: float # The minimum line coverage percentage to report. (format: double)
  --max-line-coverage-percentage: float # The maximum line coverage percentage to report. (format: double)
]: any -> oneof<record<nextToken: string, codeCoverages: table<id: string, reportARN: string, filePath: string, lineCoveragePercentage: float, linesCovered: int, linesMissed: int, branchCoveragePercentage: float, branchesCovered: int, branchesMissed: int, expired: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DescribeCodeCoverages")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"reportArn": $report_arn, "nextToken": $next_token_body, "maxResults": $max_results_body, "sortOrder": $sort_order, "sortBy": $sort_by, "minLineCoveragePercentage": $min_line_coverage_percentage, "maxLineCoveragePercentage": $max_line_coverage_percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of details about test cases for a report.
#
# POST /
# operationId: DescribeTestCases
export def "describe-test-cases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  report_arn: string # The ARN of the report for which test cases are returned.
  --next-token-body: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
  --max-results-body: int # The maximum number of paginated test cases returned per response. Use nextToken to iterate pages in the list of returned TestCase objects. The default value is 100. (body field)
  --filter: record # A filter used to return specific types of test cases. In order to pass the filter, the report must meet all of the filter properties. — shape: {status?: string, keyword?: string}
]: any -> oneof<record<nextToken: string, testCases: table<reportArn: string, testRawDataPath: string, prefix: string, name: string, status: string, durationInNanoSeconds: int, message: string, expired: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.DescribeTestCases")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"reportArn": $report_arn, "nextToken": $next_token_body, "maxResults": $max_results_body, "filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Analyzes and accumulates test report values for the specified test reports.
#
# POST /
# operationId: GetReportGroupTrend
export def "get-report-group-trend" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  report_group_arn: string # The ARN of the report group that contains the reports to analyze.
  --num-of-reports: int # The number of reports to analyze. This operation always retrieves the most recent reports. If this parameter is omitted, the most recent 100 reports are analyzed.
  trend_field: string@trend-field-completer # The test report value to accumulate. This must be one of the following values: Test reports: DURATION Accumulate the test run times for the specified reports. PASS_RATE Accumulate the percentage of tests that passed for the specified test reports. TOTAL Accumulate the total number of tests for the specified test reports. Code coverage reports: BRANCH_COVERAGE Accumulate the branch coverage percentages for the specified test reports. BRANCHES_COVERED Accumulate the branches covered values for the specified test reports. BRANCHES_MISSED Accumulate the branches missed values for the specified test reports. LINE_COVERAGE Accumulate the line coverage percentages for the specified test reports. LINES_COVERED Accumulate the lines covered values for the specified test reports. LINES_MISSED Accumulate the lines not covered values for the specified test reports.
]: any -> oneof<record<stats: record<average: string, max: string, min: string>, rawData: table<reportArn: string, data: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.GetReportGroupTrend")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"reportGroupArn": $report_group_arn, "numOfReports": $num_of_reports, "trendField": $trend_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Gets a resource policy that is identified by its resource ARN.
#
# POST /
# operationId: GetResourcePolicy
export def "get-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  resource_arn: string # The ARN of the resource that is associated with the resource policy.
]: any -> oneof<record<policy: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.GetResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Imports the source repository credentials for an CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository.
#
# POST /
# operationId: ImportSourceCredentials
export def "import-source-credentials" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  --username: string # The Bitbucket username when the authType is BASIC_AUTH. This parameter is not valid for other types of source providers or connections.
  --body-token: string # For GitHub or GitHub Enterprise, this is the personal access token. For Bitbucket, this is the app password. (format: password)
  server_type: string@server-type-completer # The source provider used for this project.
  auth_type: string@auth-type-completer # The type of authentication used to connect to a GitHub, GitHub Enterprise, or Bitbucket repository. An OAUTH connection is not supported by the API and must be created using the CodeBuild console.
  --should-overwrite: oneof<nothing, bool> # Set to false to prevent overwriting the repository source credentials. Set to true to overwrite the repository source credentials. The default value is true.
]: any -> oneof<record<arn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ImportSourceCredentials")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"username": $username, "token": $body_token, "serverType": $server_type, "authType": $auth_type, "shouldOverwrite": $should_overwrite} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "token") == null) { error make --unspanned { msg: "required body field 'token' missing: pass --body-token or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Resets the cache for a project.
#
# POST /
# operationId: InvalidateProjectCache
export def "invalidate-project-cache" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  project_name: string # The name of the CodeBuild build project that the cache is reset for.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.InvalidateProjectCache")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"projectName": $project_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Retrieves the identifiers of your build batches in the current region.
#
# POST /
# operationId: ListBuildBatches
export def "list-build-batches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  --filter: record # Specifies filters when retrieving batch builds. — shape: {status?: "SUCCEEDED"|"FAILED"|"FAULT"|"TIMED_OUT"|"IN_PROGRESS"|"STOPPED"}
  --max-results-body: int # The maximum number of results to return. (body field)
  --sort-order: string@sort-order-completer # Specifies the sort order of the returned items. Valid values include: ASCENDING: List the batch build identifiers in ascending order by identifier. DESCENDING: List the batch build identifiers in descending order by identifier.
  --next-token-body: string # The nextToken value returned from a previous call to ListBuildBatches. This specifies the next item to return. To return the beginning of the list, exclude this parameter. (body field)
]: any -> oneof<record<ids: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListBuildBatches")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"filter": $filter, "maxResults": $max_results_body, "sortOrder": $sort_order, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the identifiers of the build batches for a specific project.
#
# POST /
# operationId: ListBuildBatchesForProject
export def "list-build-batches-for-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  --project-name: string # The name of the project.
  --filter: record # Specifies filters when retrieving batch builds. — shape: {status?: "SUCCEEDED"|"FAILED"|"FAULT"|"TIMED_OUT"|"IN_PROGRESS"|"STOPPED"}
  --max-results-body: int # The maximum number of results to return. (body field)
  --sort-order: string@sort-order-completer # Specifies the sort order of the returned items. Valid values include: ASCENDING: List the batch build identifiers in ascending order by identifier. DESCENDING: List the batch build identifiers in descending order by identifier.
  --next-token-body: string # The nextToken value returned from a previous call to ListBuildBatchesForProject. This specifies the next item to return. To return the beginning of the list, exclude this parameter. (body field)
]: any -> oneof<record<ids: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListBuildBatchesForProject")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"projectName": $project_name, "filter": $filter, "maxResults": $max_results_body, "sortOrder": $sort_order, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of build IDs, with each build ID representing a single build.
#
# POST /
# operationId: ListBuilds
export def "list-builds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  --sort-order: string@sort-order-completer # The order to list build IDs. Valid values include: ASCENDING: List the build IDs in ascending order by build ID. DESCENDING: List the build IDs in descending order by build ID.
  --next-token-body: string # During a previous call, if there are more than 100 items in the list, only the first 100 items are returned, along with a unique string called a nextToken. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
]: any -> oneof<record<ids: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListBuilds")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"sortOrder": $sort_order, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of build identifiers for the specified build project, with each build identifier representing a single build.
#
# POST /
# operationId: ListBuildsForProject
export def "list-builds-for-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  project_name: string # The name of the CodeBuild project.
  --sort-order: string@sort-order-completer # The order to sort the results in. The results are sorted by build number, not the build identifier. If this is not specified, the results are sorted in descending order. Valid values include: ASCENDING: List the build identifiers in ascending order, by build number. DESCENDING: List the build identifiers in descending order, by build number. If the project has more than 100 builds, setting the sort order will result in an error.
  --next-token-body: string # During a previous call, if there are more than 100 items in the list, only the first 100 items are returned, along with a unique string called a nextToken. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
]: any -> oneof<record<ids: list<string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListBuildsForProject")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"projectName": $project_name, "sortOrder": $sort_order, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets information about Docker images that are managed by CodeBuild.
#
# POST /
# operationId: ListCuratedEnvironmentImages
export def "list-curated-environment-images" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  --body: record
]: any -> oneof<record<platforms: table<platform: string, languages: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListCuratedEnvironmentImages")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Gets a list of build project names, with each build project name representing a single build project.
#
# POST /
# operationId: ListProjects
export def "list-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27 # required
  --sort-by: string@sort-by-completer-1 # The criterion to be used to list build project names. Valid values include: CREATED_TIME: List based on when each build project was created. LAST_MODIFIED_TIME: List based on when information about each build project was last changed. NAME: List based on each build project's name. Use sortOrder to specify in what order to list the build project names based on the preceding criteria.
  --sort-order: string@sort-order-completer # The order in which to list build projects. Valid values include: ASCENDING: List in ascending order. DESCENDING: List in descending order. Use sortBy to specify the criterion to be used to list build project names.
  --next-token-body: string # During a previous call, if there are more than 100 items in the list, only the first 100 items are returned, along with a unique string called a nextToken. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
]: any -> oneof<record<nextToken: string, projects: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListProjects")
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "sortOrder": $sort_order, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list ARNs for the report groups in the current Amazon Web Services account.
#
# POST /
# operationId: ListReportGroups
export def "list-report-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --sort-order: string@sort-order-completer # Used to specify the order to sort the list of returned report groups. Valid values are ASCENDING and DESCENDING.
  --sort-by: string@sort-by-completer-1 # The criterion to be used to list build report groups. Valid values include: CREATED_TIME: List based on when each report group was created. LAST_MODIFIED_TIME: List based on when each report group was last changed. NAME: List based on each report group's name.
  --next-token-body: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
  --max-results-body: int # The maximum number of paginated report groups returned per response. Use nextToken to iterate pages in the list of returned ReportGroup objects. The default value is 100. (body field)
]: any -> oneof<record<nextToken: string, reportGroups: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListReportGroups")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"sortOrder": $sort_order, "sortBy": $sort_by, "nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of ARNs for the reports in the current Amazon Web Services account.
#
# POST /
# operationId: ListReports
export def "list-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  --sort-order: string@sort-order-completer # Specifies the sort order for the list of returned reports. Valid values are: ASCENDING: return reports in chronological order based on their creation date. DESCENDING: return reports in the reverse chronological order based on their creation date.
  --next-token-body: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
  --max-results-body: int # The maximum number of paginated reports returned per response. Use nextToken to iterate pages in the list of returned Report objects. The default value is 100. (body field)
  --filter: record # A filter used to return reports with the status specified by the input status parameter. — shape: {status?: "GENERATING"|"SUCCEEDED"|"FAILED"|"INCOMPLETE"|"DELETING"}
]: any -> oneof<record<nextToken: string, reports: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListReports")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"sortOrder": $sort_order, "nextToken": $next_token_body, "maxResults": $max_results_body, "filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of ARNs for the reports that belong to a ReportGroup.
#
# POST /
# operationId: ListReportsForReportGroup
export def "list-reports-for-report-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  report_group_arn: string # The ARN of the report group for which you want to return report ARNs.
  --next-token-body: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
  --sort-order: string@sort-order-completer # Use to specify whether the results are returned in ascending or descending order.
  --max-results-body: int # The maximum number of paginated reports in this report group returned per response. Use nextToken to iterate pages in the list of returned Report objects. The default value is 100. (body field)
  --filter: record # A filter used to return reports with the status specified by the input status parameter. — shape: {status?: "GENERATING"|"SUCCEEDED"|"FAILED"|"INCOMPLETE"|"DELETING"}
]: any -> oneof<record<nextToken: string, reports: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListReportsForReportGroup")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"reportGroupArn": $report_group_arn, "nextToken": $next_token_body, "sortOrder": $sort_order, "maxResults": $max_results_body, "filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of projects that are shared with other Amazon Web Services accounts or users.
#
# POST /
# operationId: ListSharedProjects
export def "list-shared-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  --sort-by: string@sort-by-completer-2 # The criterion to be used to list build projects shared with the current Amazon Web Services account or user. Valid values include: ARN: List based on the ARN. MODIFIED_TIME: List based on when information about the shared project was last changed.
  --sort-order: string@sort-order-completer # The order in which to list shared build projects. Valid values include: ASCENDING: List in ascending order. DESCENDING: List in descending order.
  --max-results-body: int # The maximum number of paginated shared build projects returned per response. Use nextToken to iterate pages in the list of returned Project objects. The default value is 100. (body field)
  --next-token-body: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
]: any -> oneof<record<nextToken: string, projects: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListSharedProjects")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"sortBy": $sort_by, "sortOrder": $sort_order, "maxResults": $max_results_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a list of report groups that are shared with other Amazon Web Services accounts or users.
#
# POST /
# operationId: ListSharedReportGroups
export def "list-shared-report-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  --sort-order: string@sort-order-completer # The order in which to list shared report groups. Valid values include: ASCENDING: List in ascending order. DESCENDING: List in descending order.
  --sort-by: string@sort-by-completer-2 # The criterion to be used to list report groups shared with the current Amazon Web Services account or user. Valid values include: ARN: List based on the ARN. MODIFIED_TIME: List based on when information about the shared report group was last changed.
  --next-token-body: string # During a previous call, the maximum number of items that can be returned is the value specified in maxResults. If there more items in the list, then a unique string called a nextToken is returned. To get the next batch of items in the list, call this operation again, adding the next token to the call. To get all of the items in the list, keep calling this operation with each subsequent next token that is returned, until no more next tokens are returned. (body field)
  --max-results-body: int # The maximum number of paginated shared report groups per response. Use nextToken to iterate pages in the list of returned ReportGroup objects. The default value is 100. (body field)
]: any -> oneof<record<nextToken: string, reportGroups: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListSharedReportGroups")
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"sortOrder": $sort_order, "sortBy": $sort_by, "nextToken": $next_token_body, "maxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"maxResults": $max_results, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of SourceCredentialsInfo objects.
#
# POST /
# operationId: ListSourceCredentials
export def "list-source-credentials" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  --body: record
]: any -> oneof<record<sourceCredentialsInfos: table<arn: string, serverType: string, authType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.ListSourceCredentials")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Stores a resource policy for the ARN of a Project or ReportGroup object.
#
# POST /
# operationId: PutResourcePolicy
export def "put-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  policy: string # A JSON-formatted resource policy. For more information, see Sharing a Project (https://docs.aws.amazon.com/codebuild/latest/userguide/project-sharing.html#project-sharing-share) and Sharing a Report Group (https://docs.aws.amazon.com/codebuild/latest/userguide/report-groups-sharing.html#report-groups-sharing-share) in the CodeBuild User Guide.
  resource_arn: string # The ARN of the Project or ReportGroup resource you want to associate with a resource policy.
]: any -> oneof<record<resourceArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.PutResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"policy": $policy, "resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Restarts a build.
#
# POST /
# operationId: RetryBuild
export def "retry-build" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  --id: string # Specifies the identifier of the build to restart.
]: any -> oneof<record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.RetryBuild")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Restarts a failed batch build. Only batch builds that have failed can be retried.
#
# POST /
# operationId: RetryBuildBatch
export def "retry-build-batch" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  --id: string # Specifies the identifier of the batch build to restart.
  --retry-type: string@retry-type-completer # Specifies the type of retry to perform.
]: any -> oneof<record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.RetryBuildBatch")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id, "retryType": $retry_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Starts running a build.
#
# POST /
# operationId: StartBuild
export def "start-build" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  project_name: string # The name of the CodeBuild build project to start running a build.
  --secondary-sources-override: list # An array of ProjectSource objects. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources-version-override: list # An array of ProjectSourceVersion objects that specify one or more versions of the project's secondary sources to be used for this build only. — item shape: {sourceIdentifier: string, sourceVersion: string}
  --source-version: string # The version of the build input to be built, for this build only. If not specified, the latest version is used. If specified, the contents depends on the source provider: CodeCommit The commit ID, branch, or Git tag to use. GitHub The commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Bitbucket The commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Amazon S3 The version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the project level, then this sourceVersion (at the build level) takes precedence. For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --artifacts-override: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts-override: list # An array of ProjectArtifacts objects. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --environment-variables-override: list # A set of environment variables that overrides, for this build only, the latest ones already defined in the build project. — item shape: {name: string, value: string, type?: "PLAINTEXT"|"PARAMETER_STORE"|"SECRETS_MANAGER"}
  --source-type-override: string@source-type-override-completer # A source input type, for this build, that overrides the source input defined in the build project.
  --source-location-override: string # A location that overrides, for this build, the source location for the one defined in the build project.
  --source-auth-override: record # Information about the authorization settings for CodeBuild to access the source code to be built. This information is for the CodeBuild console's use only. Your code should not get or set this information directly. — shape: {type: "OAUTH", resource?: string}
  --git-clone-depth-override: int # The user-defined depth of history, with a minimum value of 0, that overrides, for this build only, any previous depth of history defined in the build project.
  --git-submodules-config-override: record # Information about the Git submodules configuration for an CodeBuild build project. — shape: {fetchSubmodules: bool}
  --buildspec-override: string # A buildspec file declaration that overrides, for this build only, the latest one already defined in the build project. If this value is set, it can be either an inline buildspec definition, the path to an alternate buildspec file relative to the value of the built-in CODEBUILD_SRC_DIR environment variable, or the path to an S3 bucket. The bucket must be in the same Amazon Web Services Region as the build project. Specify the buildspec file using its ARN (for example, arn:aws:s3:::my-codebuild-sample2/buildspec.yml). If this value is not provided or is set to an empty string, the source code must contain a buildspec file in its root directory. For more information, see Buildspec File Name and Storage Location (https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-name-storage).
  --insecure-ssl-override: oneof<nothing, bool> # Enable this flag to override the insecure SSL setting that is specified in the build project. The insecure SSL setting determines whether to ignore SSL warnings while connecting to the project source code. This override applies only if the build's source is GitHub Enterprise.
  --report-build-status-override: oneof<nothing, bool> # Set to true to report to your source provider the status of a build's start and completion. If you use this option with a source provider other than GitHub, GitHub Enterprise, or Bitbucket, an invalidInputException is thrown. To be able to report the build status to the source provider, the user associated with the source provider must have write access to the repo. If the user does not have write access, the build status cannot be updated. For more information, see Source provider access (https://docs.aws.amazon.com/codebuild/latest/userguide/access-tokens.html) in the CodeBuild User Guide. The status of a build triggered by a webhook is always reported to your source provider.
  --build-status-config-override: record # Contains information that defines how the CodeBuild build project reports the build status to the source provider. — shape: {context?: string, targetUrl?: string}
  --environment-type-override: string@environment-type-override-completer # A container type for this build that overrides the one specified in the build project.
  --image-override: string # The name of an image for this build that overrides the one specified in the build project.
  --compute-type-override: string@compute-type-override-completer # The name of a compute type for this build that overrides the one specified in the build project.
  --certificate-override: string # The name of a certificate for this build that overrides the one specified in the build project.
  --cache-override: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  --service-role-override: string # The name of a service role for this build that overrides the one specified in the build project.
  --privileged-mode-override: oneof<nothing, bool> # Enable this flag to override privileged mode in the build project.
  --timeout-in-minutes-override: int # The number of build timeout minutes, from 5 to 480 (8 hours), that overrides, for this build only, the latest setting already defined in the build project.
  --queued-timeout-in-minutes-override: int # The number of minutes a build is allowed to be queued before it times out.
  --encryption-key-override: string # The Key Management Service customer master key (CMK) that overrides the one specified in the build project. The CMK key encrypts the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --logs-config-override: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --registry-credential-override: record # Information about credentials that provide access to a private Docker registry. When this is set: imagePullCredentialsType must be set to SERVICE_ROLE. images cannot be curated or an Amazon ECR image. For more information, see Private Registry with Secrets Manager Sample for CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-private-registry.html). — shape: {credential: string, credentialProvider: "SECRETS_MANAGER"}
  --image-pull-credentials-type-override: string@image-pull-credentials-type-override-completer # The type of credentials CodeBuild uses to pull images in your build. There are two valid values: CODEBUILD Specifies that CodeBuild uses its own credentials. This requires that you modify your ECR repository policy to trust CodeBuild's service principal. SERVICE_ROLE Specifies that CodeBuild uses your build project's service role. When using a cross-account or private registry image, you must use SERVICE_ROLE credentials. When using an CodeBuild curated image, you must use CODEBUILD credentials.
  --debug-session-enabled: oneof<nothing, bool> # Specifies if session debugging is enabled for this build. For more information, see Viewing a running build in Session Manager (https://docs.aws.amazon.com/codebuild/latest/userguide/session-manager.html).
]: any -> oneof<record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.StartBuild")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"projectName": $project_name, "secondarySourcesOverride": $secondary_sources_override, "secondarySourcesVersionOverride": $secondary_sources_version_override, "sourceVersion": $source_version, "artifactsOverride": $artifacts_override, "secondaryArtifactsOverride": $secondary_artifacts_override, "environmentVariablesOverride": $environment_variables_override, "sourceTypeOverride": $source_type_override, "sourceLocationOverride": $source_location_override, "sourceAuthOverride": $source_auth_override, "gitCloneDepthOverride": $git_clone_depth_override, "gitSubmodulesConfigOverride": $git_submodules_config_override, "buildspecOverride": $buildspec_override, "insecureSslOverride": $insecure_ssl_override, "reportBuildStatusOverride": $report_build_status_override, "buildStatusConfigOverride": $build_status_config_override, "environmentTypeOverride": $environment_type_override, "imageOverride": $image_override, "computeTypeOverride": $compute_type_override, "certificateOverride": $certificate_override, "cacheOverride": $cache_override, "serviceRoleOverride": $service_role_override, "privilegedModeOverride": $privileged_mode_override, "timeoutInMinutesOverride": $timeout_in_minutes_override, "queuedTimeoutInMinutesOverride": $queued_timeout_in_minutes_override, "encryptionKeyOverride": $encryption_key_override, "logsConfigOverride": $logs_config_override, "registryCredentialOverride": $registry_credential_override, "imagePullCredentialsTypeOverride": $image_pull_credentials_type_override, "debugSessionEnabled": $debug_session_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Starts a batch build for a project.
#
# POST /
# operationId: StartBuildBatch
export def "start-build-batch" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  project_name: string # The name of the project.
  --secondary-sources-override: list # An array of ProjectSource objects that override the secondary sources defined in the batch build project. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources-version-override: list # An array of ProjectSourceVersion objects that override the secondary source versions in the batch build project. — item shape: {sourceIdentifier: string, sourceVersion: string}
  --source-version: string # The version of the batch build input to be built, for this build only. If not specified, the latest version is used. If specified, the contents depends on the source provider: CodeCommit The commit ID, branch, or Git tag to use. GitHub The commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Bitbucket The commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. Amazon S3 The version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the project level, then this sourceVersion (at the build level) takes precedence. For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --artifacts-override: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts-override: list # An array of ProjectArtifacts objects that override the secondary artifacts defined in the batch build project. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --environment-variables-override: list # An array of EnvironmentVariable objects that override, or add to, the environment variables defined in the batch build project. — item shape: {name: string, value: string, type?: "PLAINTEXT"|"PARAMETER_STORE"|"SECRETS_MANAGER"}
  --source-type-override: string@source-type-override-completer # The source input type that overrides the source input defined in the batch build project.
  --source-location-override: string # A location that overrides, for this batch build, the source location defined in the batch build project.
  --source-auth-override: record # Information about the authorization settings for CodeBuild to access the source code to be built. This information is for the CodeBuild console's use only. Your code should not get or set this information directly. — shape: {type: "OAUTH", resource?: string}
  --git-clone-depth-override: int # The user-defined depth of history, with a minimum value of 0, that overrides, for this batch build only, any previous depth of history defined in the batch build project.
  --git-submodules-config-override: record # Information about the Git submodules configuration for an CodeBuild build project. — shape: {fetchSubmodules: bool}
  --buildspec-override: string # A buildspec file declaration that overrides, for this build only, the latest one already defined in the build project. If this value is set, it can be either an inline buildspec definition, the path to an alternate buildspec file relative to the value of the built-in CODEBUILD_SRC_DIR environment variable, or the path to an S3 bucket. The bucket must be in the same Amazon Web Services Region as the build project. Specify the buildspec file using its ARN (for example, arn:aws:s3:::my-codebuild-sample2/buildspec.yml). If this value is not provided or is set to an empty string, the source code must contain a buildspec file in its root directory. For more information, see Buildspec File Name and Storage Location (https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-name-storage).
  --insecure-ssl-override: oneof<nothing, bool> # Enable this flag to override the insecure SSL setting that is specified in the batch build project. The insecure SSL setting determines whether to ignore SSL warnings while connecting to the project source code. This override applies only if the build's source is GitHub Enterprise.
  --report-build-batch-status-override: oneof<nothing, bool> # Set to true to report to your source provider the status of a batch build's start and completion. If you use this option with a source provider other than GitHub, GitHub Enterprise, or Bitbucket, an invalidInputException is thrown. The status of a build triggered by a webhook is always reported to your source provider.
  --environment-type-override: string@environment-type-override-completer # A container type for this batch build that overrides the one specified in the batch build project.
  --image-override: string # The name of an image for this batch build that overrides the one specified in the batch build project.
  --compute-type-override: string@compute-type-override-completer # The name of a compute type for this batch build that overrides the one specified in the batch build project.
  --certificate-override: string # The name of a certificate for this batch build that overrides the one specified in the batch build project.
  --cache-override: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  --service-role-override: string # The name of a service role for this batch build that overrides the one specified in the batch build project.
  --privileged-mode-override: oneof<nothing, bool> # Enable this flag to override privileged mode in the batch build project.
  --build-timeout-in-minutes-override: int # Overrides the build timeout specified in the batch build project.
  --queued-timeout-in-minutes-override: int # The number of minutes a batch build is allowed to be queued before it times out.
  --encryption-key-override: string # The Key Management Service customer master key (CMK) that overrides the one specified in the batch build project. The CMK key encrypts the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --logs-config-override: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --registry-credential-override: record # Information about credentials that provide access to a private Docker registry. When this is set: imagePullCredentialsType must be set to SERVICE_ROLE. images cannot be curated or an Amazon ECR image. For more information, see Private Registry with Secrets Manager Sample for CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-private-registry.html). — shape: {credential: string, credentialProvider: "SECRETS_MANAGER"}
  --image-pull-credentials-type-override: string@image-pull-credentials-type-override-completer # The type of credentials CodeBuild uses to pull images in your batch build. There are two valid values: CODEBUILD Specifies that CodeBuild uses its own credentials. This requires that you modify your ECR repository policy to trust CodeBuild's service principal. SERVICE_ROLE Specifies that CodeBuild uses your build project's service role. When using a cross-account or private registry image, you must use SERVICE_ROLE credentials. When using an CodeBuild curated image, you must use CODEBUILD credentials.
  --build-batch-config-override: record # Contains configuration information about a batch build project. — shape: {serviceRole?: string, combineArtifacts?: bool, restrictions?: record, timeoutInMins?: int, batchReportMode?: "REPORT_INDIVIDUAL_BUILDS"|"REPORT_AGGREGATED_BATCH"}
  --debug-session-enabled: oneof<nothing, bool> # Specifies if session debugging is enabled for this batch build. For more information, see Viewing a running build in Session Manager (https://docs.aws.amazon.com/codebuild/latest/userguide/session-manager.html). Batch session debugging is not supported for matrix batch builds.
]: any -> oneof<record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.StartBuildBatch")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"projectName": $project_name, "secondarySourcesOverride": $secondary_sources_override, "secondarySourcesVersionOverride": $secondary_sources_version_override, "sourceVersion": $source_version, "artifactsOverride": $artifacts_override, "secondaryArtifactsOverride": $secondary_artifacts_override, "environmentVariablesOverride": $environment_variables_override, "sourceTypeOverride": $source_type_override, "sourceLocationOverride": $source_location_override, "sourceAuthOverride": $source_auth_override, "gitCloneDepthOverride": $git_clone_depth_override, "gitSubmodulesConfigOverride": $git_submodules_config_override, "buildspecOverride": $buildspec_override, "insecureSslOverride": $insecure_ssl_override, "reportBuildBatchStatusOverride": $report_build_batch_status_override, "environmentTypeOverride": $environment_type_override, "imageOverride": $image_override, "computeTypeOverride": $compute_type_override, "certificateOverride": $certificate_override, "cacheOverride": $cache_override, "serviceRoleOverride": $service_role_override, "privilegedModeOverride": $privileged_mode_override, "buildTimeoutInMinutesOverride": $build_timeout_in_minutes_override, "queuedTimeoutInMinutesOverride": $queued_timeout_in_minutes_override, "encryptionKeyOverride": $encryption_key_override, "logsConfigOverride": $logs_config_override, "registryCredentialOverride": $registry_credential_override, "imagePullCredentialsTypeOverride": $image_pull_credentials_type_override, "buildBatchConfigOverride": $build_batch_config_override, "debugSessionEnabled": $debug_session_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Attempts to stop running a build.
#
# POST /
# operationId: StopBuild
export def "stop-build" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  id: string # The ID of the build.
]: any -> oneof<record<build: record<id: string, arn: string, buildNumber: int, startTime: string, endTime: string, currentPhase: string, buildStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logs: record<groupName: string, streamName: string, deepLink: string, s3DeepLink: string, cloudWatchLogsArn: string, s3LogsArn: string, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: int, queuedTimeoutInMinutes: int, buildComplete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, networkInterface: record<subnetId: string, networkInterfaceId: string>, encryptionKey: string, exportedEnvironmentVariables: list<record>, reportArns: list<string>, fileSystemLocations: list<record>, debugSession: record<sessionEnabled: bool, sessionTarget: string>, buildBatchArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.StopBuild")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Stops a running batch build.
#
# POST /
# operationId: StopBuildBatch
export def "stop-build-batch" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  id: string # The identifier of the batch build to stop.
]: any -> oneof<record<buildBatch: record<id: string, arn: string, startTime: string, endTime: string, currentPhase: string, buildBatchStatus: string, sourceVersion: string, resolvedSourceVersion: string, projectName: string, phases: list<record>, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, secondarySourceVersions: list<record>, artifacts: record<location: string, sha256sum: string, md5sum: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: int, queuedTimeoutInMinutes: int, complete: bool, initiator: string, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, encryptionKey: string, buildBatchNumber: int, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, buildGroups: list<record>, debugSessionEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.StopBuildBatch")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Changes the settings of a build project.
#
# POST /
# operationId: UpdateProject
export def "update-project" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  name: string # The name of the build project. You cannot change a build project's name.
  --description: string # A new or replacement description of the build project.
  --source: record # Information about the build input source code for the build project. — shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --secondary-sources: list # An array of ProjectSource objects. — item shape: {type: "CODECOMMIT"|"CODEPIPELINE"|"GITHUB"|"S3"|"BITBUCKET"|"GITHUB_ENTERPRISE"|"NO_SOURCE", location?: string, gitCloneDepth?: int, gitSubmodulesConfig?: record, buildspec?: string, auth?: record, reportBuildStatus?: bool, buildStatusConfig?: record, insecureSsl?: bool, sourceIdentifier?: string}
  --source-version: string # A version of the build input to be built for this project. If not specified, the latest version is used. If specified, it must be one of: For CodeCommit: the commit ID, branch, or Git tag to use. For GitHub: the commit ID, pull request ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a pull request ID is specified, it must use the format pr/pull-request-ID (for example pr/25). If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Bitbucket: the commit ID, branch name, or tag name that corresponds to the version of the source code you want to build. If a branch name is specified, the branch's HEAD commit ID is used. If not specified, the default branch's HEAD commit ID is used. For Amazon S3: the version ID of the object that represents the build input ZIP file to use. If sourceVersion is specified at the build level, then that version takes precedence over this sourceVersion (at the project level). For more information, see Source Version Sample with CodeBuild (https://docs.aws.amazon.com/codebuild/latest/userguide/sample-source-version.html) in the CodeBuild User Guide.
  --secondary-source-versions: list # An array of ProjectSourceVersion objects. If secondarySourceVersions is specified at the build level, then they take over these secondarySourceVersions (at the project level). — item shape: {sourceIdentifier: string, sourceVersion: string}
  --artifacts: record # Information about the build output artifacts for the build project. — shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --secondary-artifacts: list # An array of ProjectArtifact objects. — item shape: {type: "CODEPIPELINE"|"S3"|"NO_ARTIFACTS", location?: string, path?: string, namespaceType?: "NONE"|"BUILD_ID", name?: string, packaging?: "NONE"|"ZIP", overrideArtifactName?: bool, encryptionDisabled?: bool, artifactIdentifier?: string, bucketOwnerAccess?: "NONE"|"READ_ONLY"|"FULL"}
  --cache: record # Information about the cache for the build project. — shape: {type: "NO_CACHE"|"S3"|"LOCAL", location?: string, modes?: list<string>}
  --environment: record # Information about the build environment of the build project. — shape: {type: "WINDOWS_CONTAINER"|"LINUX_CONTAINER"|"LINUX_GPU_CONTAINER"|"ARM_CONTAINER"|"WINDOWS_SERVER_2019_CONTAINER", image: string, computeType: "BUILD_GENERAL1_SMALL"|"BUILD_GENERAL1_MEDIUM"|"BUILD_GENERAL1_LARGE"|"BUILD_GENERAL1_2XLARGE", environmentVariables?: list, privilegedMode?: bool, certificate?: string, registryCredential?: record, imagePullCredentialsType?: "CODEBUILD"|"SERVICE_ROLE"}
  --service-role: string # The replacement ARN of the IAM role that enables CodeBuild to interact with dependent Amazon Web Services services on behalf of the Amazon Web Services account.
  --timeout-in-minutes: int # The replacement value in minutes, from 5 to 480 (8 hours), for CodeBuild to wait before timing out any related build that did not get marked as completed.
  --queued-timeout-in-minutes: int # The number of minutes a build is allowed to be queued before it times out.
  --encryption-key: string # The Key Management Service customer master key (CMK) to be used for encrypting the build output artifacts. You can use a cross-account KMS key to encrypt the build output artifacts if your service role has permission to that key. You can specify either the Amazon Resource Name (ARN) of the CMK or, if available, the CMK's alias (using the format alias/<alias-name>).
  --tags: list # An updated list of tag key and value pairs associated with this build project. These tags are available for use by Amazon Web Services services that support CodeBuild build project tags. — item shape: {key?: string, value?: string}
  --vpc-config: record # Information about the VPC configuration that CodeBuild accesses. — shape: {vpcId?: string, subnets?: list<string>, securityGroupIds?: list<string>}
  --badge-enabled: oneof<nothing, bool> # Set this to true to generate a publicly accessible URL for your project's build badge.
  --logs-config: record # Information about logs for a build project. These can be logs in CloudWatch Logs, built in a specified S3 bucket, or both. — shape: {cloudWatchLogs?: record, s3Logs?: record}
  --file-system-locations: list # An array of ProjectFileSystemLocation objects for a CodeBuild build project. A ProjectFileSystemLocation object specifies the identifier, location, mountOptions, mountPoint, and type of a file system created using Amazon Elastic File System. — item shape: {type?: "EFS", location?: string, mountPoint?: string, identifier?: string, mountOptions?: string}
  --build-batch-config: record # Contains configuration information about a batch build project. — shape: {serviceRole?: string, combineArtifacts?: bool, restrictions?: record, timeoutInMins?: int, batchReportMode?: "REPORT_INDIVIDUAL_BUILDS"|"REPORT_AGGREGATED_BATCH"}
  --concurrent-build-limit: int # The maximum number of concurrent builds that are allowed for this project. New builds are only started if the current number of builds is less than or equal to this limit. If the current build count meets this limit, new builds are throttled and are not run. To remove this limit, set this value to -1.
]: any -> oneof<record<project: record<name: string, arn: string, description: string, source: record<type: string, location: string, gitCloneDepth: int, gitSubmodulesConfig: record, buildspec: string, auth: record, reportBuildStatus: bool, buildStatusConfig: record, insecureSsl: bool, sourceIdentifier: string>, secondarySources: list<record>, sourceVersion: string, secondarySourceVersions: list<record>, artifacts: record<type: string, location: string, path: string, namespaceType: string, name: string, packaging: string, overrideArtifactName: bool, encryptionDisabled: bool, artifactIdentifier: string, bucketOwnerAccess: string>, secondaryArtifacts: list<record>, cache: record<type: string, location: string, modes: list>, environment: record<type: string, image: string, computeType: string, environmentVariables: list, privilegedMode: bool, certificate: string, registryCredential: record, imagePullCredentialsType: string>, serviceRole: string, timeoutInMinutes: int, queuedTimeoutInMinutes: int, encryptionKey: string, tags: list<record>, created: string, lastModified: string, webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list, buildType: string, lastModifiedSecret: string>, vpcConfig: record<vpcId: string, subnets: list, securityGroupIds: list>, badge: record<badgeEnabled: bool, badgeRequestUrl: string>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: list<record>, buildBatchConfig: record<serviceRole: string, combineArtifacts: bool, restrictions: record, timeoutInMins: int, batchReportMode: string>, concurrentBuildLimit: int, projectVisibility: string, publicProjectAlias: string, resourceAccessRole: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.UpdateProject")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"name": $name, "description": $description, "source": $source, "secondarySources": $secondary_sources, "sourceVersion": $source_version, "secondarySourceVersions": $secondary_source_versions, "artifacts": $artifacts, "secondaryArtifacts": $secondary_artifacts, "cache": $cache, "environment": $environment, "serviceRole": $service_role, "timeoutInMinutes": $timeout_in_minutes, "queuedTimeoutInMinutes": $queued_timeout_in_minutes, "encryptionKey": $encryption_key, "tags": $tags, "vpcConfig": $vpc_config, "badgeEnabled": $badge_enabled, "logsConfig": $logs_config, "fileSystemLocations": $file_system_locations, "buildBatchConfig": $build_batch_config, "concurrentBuildLimit": $concurrent_build_limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Changes the public visibility for a project. The project's build results, logs, and artifacts are available to the general public. For more information, see Public build projects (https://docs.aws.amazon.com/codebuild/latest/userguide/public-builds.html) in the CodeBuild User Guide. The following should be kept in mind when making your projects public: All of a project's build results, logs, and artifacts, including builds that were run when the project was private, are available to the general public. All build logs and artifacts are available to the public. Environment variables, source code, and other sensitive information may have been output to the build logs and artifacts. You must be careful about what information is output to the build logs. Some best practice are: Do not store sensitive values, especially Amazon Web Services access key IDs and secret access keys, in environment variables. We recommend that you use an Amazon EC2 Systems Manager Parameter Store or Secrets Manager to store sensitive values. Follow Best practices for using webhooks (https://docs.aws.amazon.com/codebuild/latest/userguide/webhooks.html#webhook-best-practices) in the CodeBuild User Guide to limit which entities can trigger a build, and do not store the buildspec in the project itself, to ensure that your webhooks are as secure as possible. A malicious user can use public builds to distribute malicious artifacts. We recommend that you review all pull requests to verify that the pull request is a legitimate change. We also recommend that you validate any artifacts with their checksums to make sure that the correct artifacts are being downloaded.
#
# POST /
# operationId: UpdateProjectVisibility
export def "update-project-visibility" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  project_arn: string # The Amazon Resource Name (ARN) of the build project.
  project_visibility: string@project-visibility-completer # Specifies the visibility of the project's builds. Possible values are: PUBLIC_READ The project builds are visible to the public. PRIVATE The project builds are not visible to the public.
  --resource-access-role: string # The ARN of the IAM role that enables CodeBuild to access the CloudWatch Logs and Amazon S3 artifacts for the project's builds.
]: any -> oneof<record<projectArn: string, publicProjectAlias: string, projectVisibility: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.UpdateProjectVisibility")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"projectArn": $project_arn, "projectVisibility": $project_visibility, "resourceAccessRole": $resource_access_role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Updates a report group.
#
# POST /
# operationId: UpdateReportGroup
export def "update-report-group" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  arn: string # The ARN of the report group to update.
  --export-config: record # Information about the location where the run of a report is exported. — shape: {exportConfigType?: "S3"|"NO_EXPORT", s3Destination?: record}
  --tags: list # An updated list of tag key and value pairs associated with this report group. These tags are available for use by Amazon Web Services services that support CodeBuild report group tags. — item shape: {key?: string, value?: string}
]: any -> oneof<record<reportGroup: record<arn: string, name: string, type: string, exportConfig: record<exportConfigType: string, s3Destination: record>, created: string, lastModified: string, tags: list<record>, status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.UpdateReportGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"arn": $arn, "exportConfig": $export_config, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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

# Updates the webhook associated with an CodeBuild build project. If you use Bitbucket for your repository, rotateSecret is ignored.
#
# POST /
# operationId: UpdateWebhook
export def "update-webhook" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  project_name: string # The name of the CodeBuild project.
  --branch-filter: string # A regular expression used to determine which repository branches are built when a webhook is triggered. If the name of a branch matches the regular expression, then it is built. If branchFilter is empty, then all branches are built. It is recommended that you use filterGroups instead of branchFilter.
  --rotate-secret: oneof<nothing, bool> # A boolean value that specifies whether the associated GitHub repository's secret token should be updated. If you use Bitbucket for your repository, rotateSecret is ignored.
  --filter-groups: list # An array of arrays of WebhookFilter objects used to determine if a webhook event can trigger a build. A filter group must contain at least one EVENT WebhookFilter.
  --build-type: string@build-type-completer # Specifies the type of build this webhook will trigger.
]: any -> oneof<record<webhook: record<url: string, payloadUrl: string, secret: string, branchFilter: string, filterGroups: list<list>, buildType: string, lastModifiedSecret: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "CodeBuild_20161006.UpdateWebhook")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"projectName": $project_name, "branchFilter": $branch_filter, "rotateSecret": $rotate_secret, "filterGroups": $filter_groups, "buildType": $build_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
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
