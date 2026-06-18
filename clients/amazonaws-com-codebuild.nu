# Auto-generated client for AWS CodeBuild v2016-10-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/codebuild/2016-10-06/openapi.json
# Auth: --token flag or $env.AWS_CODEBUILD_TOKEN

const BASE_URL = "http://codebuild.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_CODEBUILD_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
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
def x-amz-target-completer-7 [] { ["CodeBuild_20161006.CreateReportGroup"] }
def x-amz-target-completer-8 [] { ["CodeBuild_20161006.CreateWebhook"] }
def x-amz-target-completer-9 [] { ["CodeBuild_20161006.DeleteBuildBatch"] }
def x-amz-target-completer-10 [] { ["CodeBuild_20161006.DeleteProject"] }
def x-amz-target-completer-11 [] { ["CodeBuild_20161006.DeleteReport"] }
def x-amz-target-completer-12 [] { ["CodeBuild_20161006.DeleteReportGroup"] }
def x-amz-target-completer-13 [] { ["CodeBuild_20161006.DeleteResourcePolicy"] }
def x-amz-target-completer-14 [] { ["CodeBuild_20161006.DeleteSourceCredentials"] }
def x-amz-target-completer-15 [] { ["CodeBuild_20161006.DeleteWebhook"] }
def x-amz-target-completer-16 [] { ["CodeBuild_20161006.DescribeCodeCoverages"] }
def x-amz-target-completer-17 [] { ["CodeBuild_20161006.DescribeTestCases"] }
def x-amz-target-completer-18 [] { ["CodeBuild_20161006.GetReportGroupTrend"] }
def x-amz-target-completer-19 [] { ["CodeBuild_20161006.GetResourcePolicy"] }
def x-amz-target-completer-20 [] { ["CodeBuild_20161006.ImportSourceCredentials"] }
def x-amz-target-completer-21 [] { ["CodeBuild_20161006.InvalidateProjectCache"] }
def x-amz-target-completer-22 [] { ["CodeBuild_20161006.ListBuildBatches"] }
def x-amz-target-completer-23 [] { ["CodeBuild_20161006.ListBuildBatchesForProject"] }
def x-amz-target-completer-24 [] { ["CodeBuild_20161006.ListBuilds"] }
def x-amz-target-completer-25 [] { ["CodeBuild_20161006.ListBuildsForProject"] }
def x-amz-target-completer-26 [] { ["CodeBuild_20161006.ListCuratedEnvironmentImages"] }
def x-amz-target-completer-27 [] { ["CodeBuild_20161006.ListProjects"] }
def x-amz-target-completer-28 [] { ["CodeBuild_20161006.ListReportGroups"] }
def x-amz-target-completer-29 [] { ["CodeBuild_20161006.ListReports"] }
def x-amz-target-completer-30 [] { ["CodeBuild_20161006.ListReportsForReportGroup"] }
def x-amz-target-completer-31 [] { ["CodeBuild_20161006.ListSharedProjects"] }
def x-amz-target-completer-32 [] { ["CodeBuild_20161006.ListSharedReportGroups"] }
def x-amz-target-completer-33 [] { ["CodeBuild_20161006.ListSourceCredentials"] }
def x-amz-target-completer-34 [] { ["CodeBuild_20161006.PutResourcePolicy"] }
def x-amz-target-completer-35 [] { ["CodeBuild_20161006.RetryBuild"] }
def x-amz-target-completer-36 [] { ["CodeBuild_20161006.RetryBuildBatch"] }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-code-build-20161006-batch-delete-builds delete" } } | get name | first)
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

# Deletes one or more builds.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds
# operationId: BatchDeleteBuilds
export def "x-amz-target-code-build-20161006-batch-delete-builds delete" [
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
  --x-amz-target: string@x-amz-target-completer
  ids: any
]: any -> record<buildsDeleted: record, buildsNotDeleted: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves information about one or more batch builds.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetBuildBatches
# operationId: BatchGetBuildBatches
export def "x-amz-target-code-build-20161006-batch-get-build-batches get" [
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
  --x-amz-target: string@x-amz-target-completer-1
  ids: any
]: any -> record<buildBatches: record, buildBatchesNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuildBatches")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about one or more builds.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds
# operationId: BatchGetBuilds
export def "x-amz-target-code-build-20161006-batch-get-builds get" [
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
  --x-amz-target: string@x-amz-target-completer-2
  ids: any
]: any -> record<builds: record, buildsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about one or more build projects.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetProjects
# operationId: BatchGetProjects
export def "x-amz-target-code-build-20161006-batch-get-projects get" [
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
  --x-amz-target: string@x-amz-target-completer-3
  names: any
]: any -> record<projects: record, projectsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects")
  let req_body = {"names": $names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns an array of report groups.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetReportGroups
# operationId: BatchGetReportGroups
export def "x-amz-target-code-build-20161006-batch-get-report-groups get" [
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
  --x-amz-target: string@x-amz-target-completer-4
  report_group_arns: any
]: any -> record<reportGroups: record, reportGroupsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetReportGroups")
  let req_body = {"reportGroupArns": $report_group_arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns an array of reports.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetReports
# operationId: BatchGetReports
export def "x-amz-target-code-build-20161006-batch-get-reports get" [
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
  --x-amz-target: string@x-amz-target-completer-5
  report_arns: any
]: any -> record<reports: record, reportsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetReports")
  let req_body = {"reportArns": $report_arns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a build project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.CreateProject
# operationId: CreateProject
export def "x-amz-target-code-build-20161006-create-project create" [
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
  --x-amz-target: string@x-amz-target-completer-6
  name: any
  --description: any
  --body-source: any
  --secondary-sources: any
  --source-version: any
  --secondary-source-versions: any
  artifacts: any
  --secondary-artifacts: any
  --cache: any
  environment: any
  service_role: any
  --timeout-in-minutes: any
  --queued-timeout-in-minutes: any
  --encryption-key: any
  --tags: any
  --vpc-config: any
  --badge-enabled: any
  --logs-config: any
  --file-system-locations: any
  --build-batch-config: any
  --concurrent-build-limit: any
]: any -> record<project: record<name: record, arn: record, description: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, sourceVersion: record, secondarySourceVersions: record, artifacts: record<type: record, location: record, path: record, namespaceType: record, name: record, packaging: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, timeoutInMinutes: record, queuedTimeoutInMinutes: record, encryptionKey: record, tags: record, created: record, lastModified: record, webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, badge: record<badgeEnabled: record, badgeRequestUrl: record>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, concurrentBuildLimit: record, projectVisibility: string, publicProjectAlias: record, resourceAccessRole: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.CreateProject")
  let req_body = {"name": $name, "description": $description, "source": $body_source, "secondarySources": $secondary_sources, "sourceVersion": $source_version, "secondarySourceVersions": $secondary_source_versions, "artifacts": $artifacts, "secondaryArtifacts": $secondary_artifacts, "cache": $cache, "environment": $environment, "serviceRole": $service_role, "timeoutInMinutes": $timeout_in_minutes, "queuedTimeoutInMinutes": $queued_timeout_in_minutes, "encryptionKey": $encryption_key, "tags": $tags, "vpcConfig": $vpc_config, "badgeEnabled": $badge_enabled, "logsConfig": $logs_config, "fileSystemLocations": $file_system_locations, "buildBatchConfig": $build_batch_config, "concurrentBuildLimit": $concurrent_build_limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a report group. A report group contains a collection of reports.
#
# POST /#X-Amz-Target=CodeBuild_20161006.CreateReportGroup
# operationId: CreateReportGroup
export def "x-amz-target-code-build-20161006-create-report-group create" [
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
  --x-amz-target: string@x-amz-target-completer-7
  name: any
  type: any
  export_config: any
  --tags: any
]: any -> record<reportGroup: record<arn: record, name: record, type: record, exportConfig: record<exportConfigType: record, s3Destination: record>, created: record, lastModified: record, tags: record, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.CreateReportGroup")
  let req_body = {"name": $name, "type": $type, "exportConfig": $export_config, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables CodeBuild to start rebuilding the source code every time a code change is pushed to the repository. If you enable webhooks for an CodeBuild project, and the project is used as a build step in CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using CodePipeline, we recommend that you disable webhooks in CodeBuild. In the CodeBuild console, clear the Webhook box. For more information, see step 5 in Change a Build Project's Settings (https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console).
#
# POST /#X-Amz-Target=CodeBuild_20161006.CreateWebhook
# operationId: CreateWebhook
export def "x-amz-target-code-build-20161006-create-webhook create" [
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
  --x-amz-target: string@x-amz-target-completer-8
  project_name: any
  --branch-filter: any
  --filter-groups: any
  --build-type: any
]: any -> record<webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook")
  let req_body = {"projectName": $project_name, "branchFilter": $branch_filter, "filterGroups": $filter_groups, "buildType": $build_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a batch build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteBuildBatch
# operationId: DeleteBuildBatch
export def "x-amz-target-code-build-20161006-delete-build-batch delete" [
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
  --x-amz-target: string@x-amz-target-completer-9
  id: any
]: any -> record<statusCode: record, buildsDeleted: record, buildsNotDeleted: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteBuildBatch")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a build project. When you delete a project, its builds are not deleted.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteProject
# operationId: DeleteProject
export def "x-amz-target-code-build-20161006-delete-project delete" [
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
  --x-amz-target: string@x-amz-target-completer-10
  name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteProject")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a report.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteReport
# operationId: DeleteReport
export def "x-amz-target-code-build-20161006-delete-report delete" [
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
  --x-amz-target: string@x-amz-target-completer-11
  arn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteReport")
  let req_body = {"arn": $arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a report group. Before you delete a report group, you must delete its reports.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteReportGroup
# operationId: DeleteReportGroup
export def "x-amz-target-code-build-20161006-delete-report-group delete" [
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
  --x-amz-target: string@x-amz-target-completer-12
  arn: any
  --delete-reports: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteReportGroup")
  let req_body = {"arn": $arn, "deleteReports": $delete_reports} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a resource policy that is identified by its resource ARN.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteResourcePolicy
# operationId: DeleteResourcePolicy
export def "x-amz-target-code-build-20161006-delete-resource-policy delete" [
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
  --x-amz-target: string@x-amz-target-completer-13
  resource_arn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteResourcePolicy")
  let req_body = {"resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials
# operationId: DeleteSourceCredentials
export def "x-amz-target-code-build-20161006-delete-source-credentials delete" [
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
  --x-amz-target: string@x-amz-target-completer-14
  arn: any
]: any -> record<arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials")
  let req_body = {"arn": $arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteWebhook
# operationId: DeleteWebhook
export def "x-amz-target-code-build-20161006-delete-webhook delete" [
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
  --x-amz-target: string@x-amz-target-completer-15
  project_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook")
  let req_body = {"projectName": $project_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves one or more code coverage reports.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DescribeCodeCoverages
# operationId: DescribeCodeCoverages
export def "x-amz-target-code-build-20161006-describe-code-coverages get" [
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
  --x-amz-target: string@x-amz-target-completer-16
  report_arn: any
  --next-token: any
  --max-results: any
  --sort-order: any
  --sort-by: any
  --min-line-coverage-percentage: any
  --max-line-coverage-percentage: any
]: any -> record<nextToken: record, codeCoverages: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DescribeCodeCoverages" $qp)
  let req_body = {"reportArn": $report_arn, "nextToken": $next_token, "maxResults": $max_results, "sortOrder": $sort_order, "sortBy": $sort_by, "minLineCoveragePercentage": $min_line_coverage_percentage, "maxLineCoveragePercentage": $max_line_coverage_percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of details about test cases for a report.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DescribeTestCases
# operationId: DescribeTestCases
export def "x-amz-target-code-build-20161006-describe-test-cases get" [
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
  --x-amz-target: string@x-amz-target-completer-17
  report_arn: any
  --next-token: any
  --max-results: any
  --filter: any
]: any -> record<nextToken: record, testCases: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DescribeTestCases" $qp)
  let req_body = {"reportArn": $report_arn, "nextToken": $next_token, "maxResults": $max_results, "filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Analyzes and accumulates test report values for the specified test reports.
#
# POST /#X-Amz-Target=CodeBuild_20161006.GetReportGroupTrend
# operationId: GetReportGroupTrend
export def "x-amz-target-code-build-20161006-get-report-group-trend get" [
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
  --x-amz-target: string@x-amz-target-completer-18
  report_group_arn: any
  --num-of-reports: any
  trend_field: any
]: any -> record<stats: record<average: record, max: record, min: record>, rawData: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.GetReportGroupTrend")
  let req_body = {"reportGroupArn": $report_group_arn, "numOfReports": $num_of_reports, "trendField": $trend_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a resource policy that is identified by its resource ARN.
#
# POST /#X-Amz-Target=CodeBuild_20161006.GetResourcePolicy
# operationId: GetResourcePolicy
export def "x-amz-target-code-build-20161006-get-resource-policy get" [
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
  --x-amz-target: string@x-amz-target-completer-19
  resource_arn: any
]: any -> record<policy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.GetResourcePolicy")
  let req_body = {"resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Imports the source repository credentials for an CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials
# operationId: ImportSourceCredentials
export def "x-amz-target-code-build-20161006-import-source-credentials import" [
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
  --x-amz-target: string@x-amz-target-completer-20
  --username: any
  --body-token: any
  server_type: any
  auth_type: any
  --should-overwrite: any
]: any -> record<arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials")
  let req_body = {"username": $username, "token": $body_token, "serverType": $server_type, "authType": $auth_type, "shouldOverwrite": $should_overwrite} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Resets the cache for a project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache
# operationId: InvalidateProjectCache
export def "x-amz-target-code-build-20161006-invalidate-project-cache create" [
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
  --x-amz-target: string@x-amz-target-completer-21
  project_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache")
  let req_body = {"projectName": $project_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves the identifiers of your build batches in the current region.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuildBatches
# operationId: ListBuildBatches
export def "x-amz-target-code-build-20161006-list-build-batches list" [
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
  --x-amz-target: string@x-amz-target-completer-22
  --filter: any
  --max-results: any
  --sort-order: any
  --next-token: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuildBatches" $qp)
  let req_body = {"filter": $filter, "maxResults": $max_results, "sortOrder": $sort_order, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves the identifiers of the build batches for a specific project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuildBatchesForProject
# operationId: ListBuildBatchesForProject
export def "x-amz-target-code-build-20161006-list-build-batches-for-project list" [
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
  --x-amz-target: string@x-amz-target-completer-23
  --project-name: any
  --filter: any
  --max-results: any
  --sort-order: any
  --next-token: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuildBatchesForProject" $qp)
  let req_body = {"projectName": $project_name, "filter": $filter, "maxResults": $max_results, "sortOrder": $sort_order, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list of build IDs, with each build ID representing a single build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuilds
# operationId: ListBuilds
export def "x-amz-target-code-build-20161006-list-builds list" [
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
  --x-amz-target: string@x-amz-target-completer-24
  --sort-order: any
  --next-token: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuilds" $qp)
  let req_body = {"sortOrder": $sort_order, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list of build identifiers for the specified build project, with each build identifier representing a single build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject
# operationId: ListBuildsForProject
export def "x-amz-target-code-build-20161006-list-builds-for-project list" [
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
  --x-amz-target: string@x-amz-target-completer-25
  project_name: any
  --sort-order: any
  --next-token: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject" $qp)
  let req_body = {"projectName": $project_name, "sortOrder": $sort_order, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about Docker images that are managed by CodeBuild.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages
# operationId: ListCuratedEnvironmentImages
export def "x-amz-target-code-build-20161006-list-curated-environment-images list" [
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
  --x-amz-target: string@x-amz-target-completer-26
  --body: record
]: any -> record<platforms: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list of build project names, with each build project name representing a single build project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListProjects
# operationId: ListProjects
export def "x-amz-target-code-build-20161006-list-projects list" [
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
  --x-amz-target: string@x-amz-target-completer-27
  --sort-by: any
  --sort-order: any
  --next-token: any
]: any -> record<nextToken: record, projects: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListProjects" $qp)
  let req_body = {"sortBy": $sort_by, "sortOrder": $sort_order, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list ARNs for the report groups in the current Amazon Web Services account.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListReportGroups
# operationId: ListReportGroups
export def "x-amz-target-code-build-20161006-list-report-groups list" [
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
  --x-amz-target: string@x-amz-target-completer-28
  --sort-order: any
  --sort-by: any
  --next-token: any
  --max-results: any
]: any -> record<nextToken: record, reportGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListReportGroups" $qp)
  let req_body = {"sortOrder": $sort_order, "sortBy": $sort_by, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of ARNs for the reports in the current Amazon Web Services account.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListReports
# operationId: ListReports
export def "x-amz-target-code-build-20161006-list-reports list" [
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
  --x-amz-target: string@x-amz-target-completer-29
  --sort-order: any
  --next-token: any
  --max-results: any
  --filter: any
]: any -> record<nextToken: record, reports: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListReports" $qp)
  let req_body = {"sortOrder": $sort_order, "nextToken": $next_token, "maxResults": $max_results, "filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of ARNs for the reports that belong to a ReportGroup.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListReportsForReportGroup
# operationId: ListReportsForReportGroup
export def "x-amz-target-code-build-20161006-list-reports-for-report-group list" [
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
  --x-amz-target: string@x-amz-target-completer-30
  report_group_arn: any
  --next-token: any
  --sort-order: any
  --max-results: any
  --filter: any
]: any -> record<nextToken: record, reports: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListReportsForReportGroup" $qp)
  let req_body = {"reportGroupArn": $report_group_arn, "nextToken": $next_token, "sortOrder": $sort_order, "maxResults": $max_results, "filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list of projects that are shared with other Amazon Web Services accounts or users.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListSharedProjects
# operationId: ListSharedProjects
export def "x-amz-target-code-build-20161006-list-shared-projects list" [
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
  --x-amz-target: string@x-amz-target-completer-31
  --sort-by: any
  --sort-order: any
  --max-results: any
  --next-token: any
]: any -> record<nextToken: record, projects: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListSharedProjects" $qp)
  let req_body = {"sortBy": $sort_by, "sortOrder": $sort_order, "maxResults": $max_results, "nextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list of report groups that are shared with other Amazon Web Services accounts or users.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListSharedReportGroups
# operationId: ListSharedReportGroups
export def "x-amz-target-code-build-20161006-list-shared-report-groups list" [
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
  --x-amz-target: string@x-amz-target-completer-32
  --sort-order: any
  --sort-by: any
  --next-token: any
  --max-results: any
]: any -> record<nextToken: record, reportGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $max_results "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListSharedReportGroups" $qp)
  let req_body = {"sortOrder": $sort_order, "sortBy": $sort_by, "nextToken": $next_token, "maxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a list of SourceCredentialsInfo objects.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials
# operationId: ListSourceCredentials
export def "x-amz-target-code-build-20161006-list-source-credentials list" [
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
  --x-amz-target: string@x-amz-target-completer-33
  --body: record
]: any -> record<sourceCredentialsInfos: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Stores a resource policy for the ARN of a Project or ReportGroup object.
#
# POST /#X-Amz-Target=CodeBuild_20161006.PutResourcePolicy
# operationId: PutResourcePolicy
export def "x-amz-target-code-build-20161006-put-resource-policy update" [
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
  --x-amz-target: string@x-amz-target-completer-34
  policy: any
  resource_arn: any
]: any -> record<resourceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.PutResourcePolicy")
  let req_body = {"policy": $policy, "resourceArn": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Restarts a build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.RetryBuild
# operationId: RetryBuild
export def "x-amz-target-code-build-20161006-retry-build build" [
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
  --x-amz-target: string@x-amz-target-completer-35
  --id: any
]: any -> record<build: record<id: record, arn: record, buildNumber: record, startTime: record, endTime: record, currentPhase: record, buildStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logs: record<groupName: record, streamName: record, deepLink: record, s3DeepLink: record, cloudWatchLogsArn: record, s3LogsArn: record, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: record, queuedTimeoutInMinutes: record, buildComplete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, networkInterface: record<subnetId: record, networkInterfaceId: record>, encryptionKey: record, exportedEnvironmentVariables: record, reportArns: record, fileSystemLocations: record, debugSession: record<sessionEnabled: record, sessionTarget: record>, buildBatchArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.RetryBuild")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Restarts a failed batch build. Only batch builds that have failed can be retried.
#
# POST /#X-Amz-Target=CodeBuild_20161006.RetryBuildBatch
# operationId: RetryBuildBatch
export def "x-amz-target-code-build-20161006-retry-build-batch build" [
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
  --x-amz-target: string@x-amz-target-completer-36
  --id: any
  --retry-type: any
]: any -> record<buildBatch: record<id: record, arn: record, startTime: record, endTime: record, currentPhase: record, buildBatchStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: record, queuedTimeoutInMinutes: record, complete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, encryptionKey: record, buildBatchNumber: record, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, buildGroups: record, debugSessionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.RetryBuildBatch")
  let req_body = {"id": $id, "retryType": $retry_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts running a build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StartBuild
# operationId: StartBuild
export def "x-amz-target-code-build-20161006-start-build start" [
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
  --x-amz-target: string@x-amz-target-completer-37
  project_name: any
  --secondary-sources-override: any
  --secondary-sources-version-override: any
  --source-version: any
  --artifacts-override: any
  --secondary-artifacts-override: any
  --environment-variables-override: any
  --source-type-override: any
  --source-location-override: any
  --source-auth-override: any
  --git-clone-depth-override: any
  --git-submodules-config-override: any
  --buildspec-override: any
  --insecure-ssl-override: any
  --report-build-status-override: any
  --build-status-config-override: any
  --environment-type-override: any
  --image-override: any
  --compute-type-override: any
  --certificate-override: any
  --cache-override: any
  --service-role-override: any
  --privileged-mode-override: any
  --timeout-in-minutes-override: any
  --queued-timeout-in-minutes-override: any
  --encryption-key-override: any
  --logs-config-override: any
  --registry-credential-override: any
  --image-pull-credentials-type-override: any
  --debug-session-enabled: any
]: any -> record<build: record<id: record, arn: record, buildNumber: record, startTime: record, endTime: record, currentPhase: record, buildStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logs: record<groupName: record, streamName: record, deepLink: record, s3DeepLink: record, cloudWatchLogsArn: record, s3LogsArn: record, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: record, queuedTimeoutInMinutes: record, buildComplete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, networkInterface: record<subnetId: record, networkInterfaceId: record>, encryptionKey: record, exportedEnvironmentVariables: record, reportArns: record, fileSystemLocations: record, debugSession: record<sessionEnabled: record, sessionTarget: record>, buildBatchArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StartBuild")
  let req_body = {"projectName": $project_name, "secondarySourcesOverride": $secondary_sources_override, "secondarySourcesVersionOverride": $secondary_sources_version_override, "sourceVersion": $source_version, "artifactsOverride": $artifacts_override, "secondaryArtifactsOverride": $secondary_artifacts_override, "environmentVariablesOverride": $environment_variables_override, "sourceTypeOverride": $source_type_override, "sourceLocationOverride": $source_location_override, "sourceAuthOverride": $source_auth_override, "gitCloneDepthOverride": $git_clone_depth_override, "gitSubmodulesConfigOverride": $git_submodules_config_override, "buildspecOverride": $buildspec_override, "insecureSslOverride": $insecure_ssl_override, "reportBuildStatusOverride": $report_build_status_override, "buildStatusConfigOverride": $build_status_config_override, "environmentTypeOverride": $environment_type_override, "imageOverride": $image_override, "computeTypeOverride": $compute_type_override, "certificateOverride": $certificate_override, "cacheOverride": $cache_override, "serviceRoleOverride": $service_role_override, "privilegedModeOverride": $privileged_mode_override, "timeoutInMinutesOverride": $timeout_in_minutes_override, "queuedTimeoutInMinutesOverride": $queued_timeout_in_minutes_override, "encryptionKeyOverride": $encryption_key_override, "logsConfigOverride": $logs_config_override, "registryCredentialOverride": $registry_credential_override, "imagePullCredentialsTypeOverride": $image_pull_credentials_type_override, "debugSessionEnabled": $debug_session_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Starts a batch build for a project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StartBuildBatch
# operationId: StartBuildBatch
export def "x-amz-target-code-build-20161006-start-build-batch start" [
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
  --x-amz-target: string@x-amz-target-completer-38
  project_name: any
  --secondary-sources-override: any
  --secondary-sources-version-override: any
  --source-version: any
  --artifacts-override: any
  --secondary-artifacts-override: any
  --environment-variables-override: any
  --source-type-override: any
  --source-location-override: any
  --source-auth-override: any
  --git-clone-depth-override: any
  --git-submodules-config-override: any
  --buildspec-override: any
  --insecure-ssl-override: any
  --report-build-batch-status-override: any
  --environment-type-override: any
  --image-override: any
  --compute-type-override: any
  --certificate-override: any
  --cache-override: any
  --service-role-override: any
  --privileged-mode-override: any
  --build-timeout-in-minutes-override: any
  --queued-timeout-in-minutes-override: any
  --encryption-key-override: any
  --logs-config-override: any
  --registry-credential-override: any
  --image-pull-credentials-type-override: any
  --build-batch-config-override: any
  --debug-session-enabled: any
]: any -> record<buildBatch: record<id: record, arn: record, startTime: record, endTime: record, currentPhase: record, buildBatchStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: record, queuedTimeoutInMinutes: record, complete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, encryptionKey: record, buildBatchNumber: record, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, buildGroups: record, debugSessionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StartBuildBatch")
  let req_body = {"projectName": $project_name, "secondarySourcesOverride": $secondary_sources_override, "secondarySourcesVersionOverride": $secondary_sources_version_override, "sourceVersion": $source_version, "artifactsOverride": $artifacts_override, "secondaryArtifactsOverride": $secondary_artifacts_override, "environmentVariablesOverride": $environment_variables_override, "sourceTypeOverride": $source_type_override, "sourceLocationOverride": $source_location_override, "sourceAuthOverride": $source_auth_override, "gitCloneDepthOverride": $git_clone_depth_override, "gitSubmodulesConfigOverride": $git_submodules_config_override, "buildspecOverride": $buildspec_override, "insecureSslOverride": $insecure_ssl_override, "reportBuildBatchStatusOverride": $report_build_batch_status_override, "environmentTypeOverride": $environment_type_override, "imageOverride": $image_override, "computeTypeOverride": $compute_type_override, "certificateOverride": $certificate_override, "cacheOverride": $cache_override, "serviceRoleOverride": $service_role_override, "privilegedModeOverride": $privileged_mode_override, "buildTimeoutInMinutesOverride": $build_timeout_in_minutes_override, "queuedTimeoutInMinutesOverride": $queued_timeout_in_minutes_override, "encryptionKeyOverride": $encryption_key_override, "logsConfigOverride": $logs_config_override, "registryCredentialOverride": $registry_credential_override, "imagePullCredentialsTypeOverride": $image_pull_credentials_type_override, "buildBatchConfigOverride": $build_batch_config_override, "debugSessionEnabled": $debug_session_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Attempts to stop running a build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StopBuild
# operationId: StopBuild
export def "x-amz-target-code-build-20161006-stop-build stop" [
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
  --x-amz-target: string@x-amz-target-completer-39
  id: any
]: any -> record<build: record<id: record, arn: record, buildNumber: record, startTime: record, endTime: record, currentPhase: record, buildStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logs: record<groupName: record, streamName: record, deepLink: record, s3DeepLink: record, cloudWatchLogsArn: record, s3LogsArn: record, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: record, queuedTimeoutInMinutes: record, buildComplete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, networkInterface: record<subnetId: record, networkInterfaceId: record>, encryptionKey: record, exportedEnvironmentVariables: record, reportArns: record, fileSystemLocations: record, debugSession: record<sessionEnabled: record, sessionTarget: record>, buildBatchArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StopBuild")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Stops a running batch build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StopBuildBatch
# operationId: StopBuildBatch
export def "x-amz-target-code-build-20161006-stop-build-batch stop" [
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
  --x-amz-target: string@x-amz-target-completer-40
  id: any
]: any -> record<buildBatch: record<id: record, arn: record, startTime: record, endTime: record, currentPhase: record, buildBatchStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: record, queuedTimeoutInMinutes: record, complete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, encryptionKey: record, buildBatchNumber: record, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, buildGroups: record, debugSessionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StopBuildBatch")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Changes the settings of a build project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateProject
# operationId: UpdateProject
# --buildBatchConfig shape: {serviceRole?: any, combineArtifacts?: any, restrictions?: any, timeoutInMins?: any, batchReportMode?: any}
export def "x-amz-target-code-build-20161006-update-project update" [
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
  --x-amz-target: string@x-amz-target-completer-41
  name: any
  --description: any
  --body-source: any
  --secondary-sources: any
  --source-version: any
  --secondary-source-versions: any
  --artifacts: any
  --secondary-artifacts: any
  --cache: any
  --environment: any
  --service-role: any
  --timeout-in-minutes: any
  --queued-timeout-in-minutes: any
  --encryption-key: any
  --tags: any
  --vpc-config: any
  --badge-enabled: any
  --logs-config: any
  --file-system-locations: any
  --build-batch-config: record # Contains configuration information about a batch build project. — shape: {serviceRole?: any, combineArtifacts?: any, restrictions?: any, timeoutInMins?: any, batchReportMode?: any}
  --concurrent-build-limit: any
]: any -> record<project: record<name: record, arn: record, description: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, sourceVersion: record, secondarySourceVersions: record, artifacts: record<type: record, location: record, path: record, namespaceType: record, name: record, packaging: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, timeoutInMinutes: record, queuedTimeoutInMinutes: record, encryptionKey: record, tags: record, created: record, lastModified: record, webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, badge: record<badgeEnabled: record, badgeRequestUrl: record>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, concurrentBuildLimit: record, projectVisibility: string, publicProjectAlias: record, resourceAccessRole: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateProject")
  let req_body = {"name": $name, "description": $description, "source": $body_source, "secondarySources": $secondary_sources, "sourceVersion": $source_version, "secondarySourceVersions": $secondary_source_versions, "artifacts": $artifacts, "secondaryArtifacts": $secondary_artifacts, "cache": $cache, "environment": $environment, "serviceRole": $service_role, "timeoutInMinutes": $timeout_in_minutes, "queuedTimeoutInMinutes": $queued_timeout_in_minutes, "encryptionKey": $encryption_key, "tags": $tags, "vpcConfig": $vpc_config, "badgeEnabled": $badge_enabled, "logsConfig": $logs_config, "fileSystemLocations": $file_system_locations, "buildBatchConfig": $build_batch_config, "concurrentBuildLimit": $concurrent_build_limit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Changes the public visibility for a project. The project's build results, logs, and artifacts are available to the general public. For more information, see Public build projects (https://docs.aws.amazon.com/codebuild/latest/userguide/public-builds.html) in the CodeBuild User Guide. The following should be kept in mind when making your projects public: All of a project's build results, logs, and artifacts, including builds that were run when the project was private, are available to the general public. All build logs and artifacts are available to the public. Environment variables, source code, and other sensitive information may have been output to the build logs and artifacts. You must be careful about what information is output to the build logs. Some best practice are: Do not store sensitive values, especially Amazon Web Services access key IDs and secret access keys, in environment variables. We recommend that you use an Amazon EC2 Systems Manager Parameter Store or Secrets Manager to store sensitive values. Follow Best practices for using webhooks (https://docs.aws.amazon.com/codebuild/latest/userguide/webhooks.html#webhook-best-practices) in the CodeBuild User Guide to limit which entities can trigger a build, and do not store the buildspec in the project itself, to ensure that your webhooks are as secure as possible. A malicious user can use public builds to distribute malicious artifacts. We recommend that you review all pull requests to verify that the pull request is a legitimate change. We also recommend that you validate any artifacts with their checksums to make sure that the correct artifacts are being downloaded.
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateProjectVisibility
# operationId: UpdateProjectVisibility
export def "x-amz-target-code-build-20161006-update-project-visibility update" [
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
  --x-amz-target: string@x-amz-target-completer-42
  project_arn: any
  project_visibility: string@project-visibility-completer # Specifies the visibility of the project's builds. Possible values are: PUBLIC_READ The project builds are visible to the public. PRIVATE The project builds are not visible to the public.
  --resource-access-role: any
]: any -> record<projectArn: record, publicProjectAlias: record, projectVisibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateProjectVisibility")
  let req_body = {"projectArn": $project_arn, "projectVisibility": $project_visibility, "resourceAccessRole": $resource_access_role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a report group.
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateReportGroup
# operationId: UpdateReportGroup
export def "x-amz-target-code-build-20161006-update-report-group update" [
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
  --x-amz-target: string@x-amz-target-completer-43
  arn: any
  --export-config: any
  --tags: any
]: any -> record<reportGroup: record<arn: record, name: record, type: record, exportConfig: record<exportConfigType: record, s3Destination: record>, created: record, lastModified: record, tags: record, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateReportGroup")
  let req_body = {"arn": $arn, "exportConfig": $export_config, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the webhook associated with an CodeBuild build project. If you use Bitbucket for your repository, rotateSecret is ignored.
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateWebhook
# operationId: UpdateWebhook
export def "x-amz-target-code-build-20161006-update-webhook update" [
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
  --x-amz-target: string@x-amz-target-completer-44
  project_name: any
  --branch-filter: any
  --rotate-secret: any
  --filter-groups: any
  --build-type: any
]: any -> record<webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook")
  let req_body = {"projectName": $project_name, "branchFilter": $branch_filter, "rotateSecret": $rotate_secret, "filterGroups": $filter_groups, "buildType": $build_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
