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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://codebuild.us-east-1.amazonaws.com" "http://codebuild.us-east-2.amazonaws.com" "http://codebuild.us-west-1.amazonaws.com" "http://codebuild.us-west-2.amazonaws.com" "http://codebuild.us-gov-west-1.amazonaws.com" "http://codebuild.us-gov-east-1.amazonaws.com" "http://codebuild.ca-central-1.amazonaws.com" "http://codebuild.eu-north-1.amazonaws.com" "http://codebuild.eu-west-1.amazonaws.com" "http://codebuild.eu-west-2.amazonaws.com" "http://codebuild.eu-west-3.amazonaws.com" "http://codebuild.eu-central-1.amazonaws.com" "http://codebuild.eu-south-1.amazonaws.com" "http://codebuild.af-south-1.amazonaws.com" "http://codebuild.ap-northeast-1.amazonaws.com" "http://codebuild.ap-northeast-2.amazonaws.com" "http://codebuild.ap-northeast-3.amazonaws.com" "http://codebuild.ap-southeast-1.amazonaws.com" "http://codebuild.ap-southeast-2.amazonaws.com" "http://codebuild.ap-east-1.amazonaws.com" "http://codebuild.ap-south-1.amazonaws.com" "http://codebuild.sa-east-1.amazonaws.com" "http://codebuild.me-south-1.amazonaws.com" "https://codebuild.us-east-1.amazonaws.com" "https://codebuild.us-east-2.amazonaws.com" "https://codebuild.us-west-1.amazonaws.com" "https://codebuild.us-west-2.amazonaws.com" "https://codebuild.us-gov-west-1.amazonaws.com" "https://codebuild.us-gov-east-1.amazonaws.com" "https://codebuild.ca-central-1.amazonaws.com" "https://codebuild.eu-north-1.amazonaws.com" "https://codebuild.eu-west-1.amazonaws.com" "https://codebuild.eu-west-2.amazonaws.com" "https://codebuild.eu-west-3.amazonaws.com" "https://codebuild.eu-central-1.amazonaws.com" "https://codebuild.eu-south-1.amazonaws.com" "https://codebuild.af-south-1.amazonaws.com" "https://codebuild.ap-northeast-1.amazonaws.com" "https://codebuild.ap-northeast-2.amazonaws.com" "https://codebuild.ap-northeast-3.amazonaws.com" "https://codebuild.ap-southeast-1.amazonaws.com" "https://codebuild.ap-southeast-2.amazonaws.com" "https://codebuild.ap-east-1.amazonaws.com" "https://codebuild.ap-south-1.amazonaws.com" "https://codebuild.sa-east-1.amazonaws.com" "https://codebuild.me-south-1.amazonaws.com" "http://codebuild.cn-north-1.amazonaws.com.cn" "http://codebuild.cn-northwest-1.amazonaws.com.cn" "https://codebuild.cn-north-1.amazonaws.com.cn" "https://codebuild.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def X-Amz-Target-completer [] { ["CodeBuild_20161006.BatchDeleteBuilds"] }
def X-Amz-Target-completer-1 [] { ["CodeBuild_20161006.BatchGetBuildBatches"] }
def X-Amz-Target-completer-2 [] { ["CodeBuild_20161006.BatchGetBuilds"] }
def X-Amz-Target-completer-3 [] { ["CodeBuild_20161006.BatchGetProjects"] }
def X-Amz-Target-completer-4 [] { ["CodeBuild_20161006.BatchGetReportGroups"] }
def X-Amz-Target-completer-5 [] { ["CodeBuild_20161006.BatchGetReports"] }
def X-Amz-Target-completer-6 [] { ["CodeBuild_20161006.CreateProject"] }
def X-Amz-Target-completer-7 [] { ["CodeBuild_20161006.CreateReportGroup"] }
def X-Amz-Target-completer-8 [] { ["CodeBuild_20161006.CreateWebhook"] }
def X-Amz-Target-completer-9 [] { ["CodeBuild_20161006.DeleteBuildBatch"] }
def X-Amz-Target-completer-10 [] { ["CodeBuild_20161006.DeleteProject"] }
def X-Amz-Target-completer-11 [] { ["CodeBuild_20161006.DeleteReport"] }
def X-Amz-Target-completer-12 [] { ["CodeBuild_20161006.DeleteReportGroup"] }
def X-Amz-Target-completer-13 [] { ["CodeBuild_20161006.DeleteResourcePolicy"] }
def X-Amz-Target-completer-14 [] { ["CodeBuild_20161006.DeleteSourceCredentials"] }
def X-Amz-Target-completer-15 [] { ["CodeBuild_20161006.DeleteWebhook"] }
def X-Amz-Target-completer-16 [] { ["CodeBuild_20161006.DescribeCodeCoverages"] }
def X-Amz-Target-completer-17 [] { ["CodeBuild_20161006.DescribeTestCases"] }
def X-Amz-Target-completer-18 [] { ["CodeBuild_20161006.GetReportGroupTrend"] }
def X-Amz-Target-completer-19 [] { ["CodeBuild_20161006.GetResourcePolicy"] }
def X-Amz-Target-completer-20 [] { ["CodeBuild_20161006.ImportSourceCredentials"] }
def X-Amz-Target-completer-21 [] { ["CodeBuild_20161006.InvalidateProjectCache"] }
def X-Amz-Target-completer-22 [] { ["CodeBuild_20161006.ListBuildBatches"] }
def X-Amz-Target-completer-23 [] { ["CodeBuild_20161006.ListBuildBatchesForProject"] }
def X-Amz-Target-completer-24 [] { ["CodeBuild_20161006.ListBuilds"] }
def X-Amz-Target-completer-25 [] { ["CodeBuild_20161006.ListBuildsForProject"] }
def X-Amz-Target-completer-26 [] { ["CodeBuild_20161006.ListCuratedEnvironmentImages"] }
def X-Amz-Target-completer-27 [] { ["CodeBuild_20161006.ListProjects"] }
def X-Amz-Target-completer-28 [] { ["CodeBuild_20161006.ListReportGroups"] }
def X-Amz-Target-completer-29 [] { ["CodeBuild_20161006.ListReports"] }
def X-Amz-Target-completer-30 [] { ["CodeBuild_20161006.ListReportsForReportGroup"] }
def X-Amz-Target-completer-31 [] { ["CodeBuild_20161006.ListSharedProjects"] }
def X-Amz-Target-completer-32 [] { ["CodeBuild_20161006.ListSharedReportGroups"] }
def X-Amz-Target-completer-33 [] { ["CodeBuild_20161006.ListSourceCredentials"] }
def X-Amz-Target-completer-34 [] { ["CodeBuild_20161006.PutResourcePolicy"] }
def X-Amz-Target-completer-35 [] { ["CodeBuild_20161006.RetryBuild"] }
def X-Amz-Target-completer-36 [] { ["CodeBuild_20161006.RetryBuildBatch"] }
def X-Amz-Target-completer-37 [] { ["CodeBuild_20161006.StartBuild"] }
def X-Amz-Target-completer-38 [] { ["CodeBuild_20161006.StartBuildBatch"] }
def X-Amz-Target-completer-39 [] { ["CodeBuild_20161006.StopBuild"] }
def X-Amz-Target-completer-40 [] { ["CodeBuild_20161006.StopBuildBatch"] }
def X-Amz-Target-completer-41 [] { ["CodeBuild_20161006.UpdateProject"] }
def projectVisibility-completer [] { ["PRIVATE" "PUBLIC_READ"] }
def X-Amz-Target-completer-42 [] { ["CodeBuild_20161006.UpdateProjectVisibility"] }
def X-Amz-Target-completer-43 [] { ["CodeBuild_20161006.UpdateReportGroup"] }
def X-Amz-Target-completer-44 [] { ["CodeBuild_20161006.UpdateWebhook"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-code-build-20161006batch-delete-builds BatchDeleteBuilds" } } | get name | first)
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
export def "x-amz-target-code-build-20161006batch-delete-builds BatchDeleteBuilds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer
  ids: any
]: any -> record<buildsDeleted: record, buildsNotDeleted: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchDeleteBuilds")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves information about one or more batch builds.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetBuildBatches
# operationId: BatchGetBuildBatches
export def "x-amz-target-code-build-20161006batch-get-build-batches BatchGetBuildBatches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-1
  ids: any
]: any -> record<buildBatches: record, buildBatchesNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuildBatches")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets information about one or more builds.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds
# operationId: BatchGetBuilds
export def "x-amz-target-code-build-20161006batch-get-builds BatchGetBuilds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-2
  ids: any
]: any -> record<builds: record, buildsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetBuilds")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets information about one or more build projects.
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetProjects
# operationId: BatchGetProjects
export def "x-amz-target-code-build-20161006batch-get-projects BatchGetProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-3
  names: any
]: any -> record<projects: record, projectsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetProjects")
  let body = {names: $names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Returns an array of report groups. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetReportGroups
# operationId: BatchGetReportGroups
export def "x-amz-target-code-build-20161006batch-get-report-groups BatchGetReportGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-4
  reportGroupArns: any
]: any -> record<reportGroups: record, reportGroupsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetReportGroups")
  let body = {reportGroupArns: $reportGroupArns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Returns an array of reports. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.BatchGetReports
# operationId: BatchGetReports
export def "x-amz-target-code-build-20161006batch-get-reports BatchGetReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-5
  reportArns: any
]: any -> record<reports: record, reportsNotFound: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.BatchGetReports")
  let body = {reportArns: $reportArns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a build project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.CreateProject
# operationId: CreateProject
export def "x-amz-target-code-build-20161006create-project CreateProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-6
  name: any
  --description: any
  --body-source: any
  --secondarySources: any
  --sourceVersion: any
  --secondarySourceVersions: any
  artifacts: any
  --secondaryArtifacts: any
  --cache: any
  environment: any
  serviceRole: any
  --timeoutInMinutes: any
  --queuedTimeoutInMinutes: any
  --encryptionKey: any
  --tags: any
  --vpcConfig: any
  --badgeEnabled: any
  --logsConfig: any
  --fileSystemLocations: any
  --buildBatchConfig: any
  --concurrentBuildLimit: any
]: any -> record<project: record<name: record, arn: record, description: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, sourceVersion: record, secondarySourceVersions: record, artifacts: record<type: record, location: record, path: record, namespaceType: record, name: record, packaging: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, timeoutInMinutes: record, queuedTimeoutInMinutes: record, encryptionKey: record, tags: record, created: record, lastModified: record, webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, badge: record<badgeEnabled: record, badgeRequestUrl: record>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, concurrentBuildLimit: record, projectVisibility: string, publicProjectAlias: record, resourceAccessRole: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.CreateProject")
  let body = {name: $name, description: $description, source: $body_source, secondarySources: $secondarySources, sourceVersion: $sourceVersion, secondarySourceVersions: $secondarySourceVersions, artifacts: $artifacts, secondaryArtifacts: $secondaryArtifacts, cache: $cache, environment: $environment, serviceRole: $serviceRole, timeoutInMinutes: $timeoutInMinutes, queuedTimeoutInMinutes: $queuedTimeoutInMinutes, encryptionKey: $encryptionKey, tags: $tags, vpcConfig: $vpcConfig, badgeEnabled: $badgeEnabled, logsConfig: $logsConfig, fileSystemLocations: $fileSystemLocations, buildBatchConfig: $buildBatchConfig, concurrentBuildLimit: $concurrentBuildLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Creates a report group. A report group contains a collection of reports. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.CreateReportGroup
# operationId: CreateReportGroup
export def "x-amz-target-code-build-20161006create-report-group CreateReportGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-7
  name: any
  type: any
  exportConfig: any
  --tags: any
]: any -> record<reportGroup: record<arn: record, name: record, type: record, exportConfig: record<exportConfigType: record, s3Destination: record>, created: record, lastModified: record, tags: record, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.CreateReportGroup")
  let body = {name: $name, type: $type, exportConfig: $exportConfig, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, enables CodeBuild to start rebuilding the source code every time a code change is pushed to the repository.</p> <important> <p>If you enable webhooks for an CodeBuild project, and the project is used as a build step in CodePipeline, then two identical builds are created for each commit. One build is triggered through webhooks, and one through CodePipeline. Because billing is on a per-build basis, you are billed for both builds. Therefore, if you are using CodePipeline, we recommend that you disable webhooks in CodeBuild. In the CodeBuild console, clear the Webhook box. For more information, see step 5 in <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/change-project.html#change-project-console">Change a Build Project's Settings</a>.</p> </important>
#
# POST /#X-Amz-Target=CodeBuild_20161006.CreateWebhook
# operationId: CreateWebhook
export def "x-amz-target-code-build-20161006create-webhook CreateWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-8
  projectName: any
  --branchFilter: any
  --filterGroups: any
  --buildType: any
]: any -> record<webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.CreateWebhook")
  let body = {projectName: $projectName, branchFilter: $branchFilter, filterGroups: $filterGroups, buildType: $buildType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a batch build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteBuildBatch
# operationId: DeleteBuildBatch
export def "x-amz-target-code-build-20161006delete-build-batch DeleteBuildBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-9
  id: any
]: any -> record<statusCode: record, buildsDeleted: record, buildsNotDeleted: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteBuildBatch")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Deletes a build project. When you delete a project, its builds are not deleted. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteProject
# operationId: DeleteProject
export def "x-amz-target-code-build-20161006delete-project DeleteProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-10
  name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteProject")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Deletes a report. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteReport
# operationId: DeleteReport
export def "x-amz-target-code-build-20161006delete-report DeleteReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-11
  arn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteReport")
  let body = {arn: $arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a report group. Before you delete a report group, you must delete its reports. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteReportGroup
# operationId: DeleteReportGroup
export def "x-amz-target-code-build-20161006delete-report-group DeleteReportGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-12
  arn: any
  --deleteReports: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteReportGroup")
  let body = {arn: $arn, deleteReports: $deleteReports} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Deletes a resource policy that is identified by its resource ARN. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteResourcePolicy
# operationId: DeleteResourcePolicy
export def "x-amz-target-code-build-20161006delete-resource-policy DeleteResourcePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-13
  resourceArn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteResourcePolicy")
  let body = {resourceArn: $resourceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Deletes a set of GitHub, GitHub Enterprise, or Bitbucket source credentials. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials
# operationId: DeleteSourceCredentials
export def "x-amz-target-code-build-20161006delete-source-credentials DeleteSourceCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-14
  arn: any
]: any -> record<arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteSourceCredentials")
  let body = {arn: $arn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# For an existing CodeBuild build project that has its source code stored in a GitHub or Bitbucket repository, stops CodeBuild from rebuilding the source code every time a code change is pushed to the repository.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DeleteWebhook
# operationId: DeleteWebhook
export def "x-amz-target-code-build-20161006delete-webhook DeleteWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-15
  projectName: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DeleteWebhook")
  let body = {projectName: $projectName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves one or more code coverage reports.
#
# POST /#X-Amz-Target=CodeBuild_20161006.DescribeCodeCoverages
# operationId: DescribeCodeCoverages
export def "x-amz-target-code-build-20161006describe-code-coverages DescribeCodeCoverages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-16
  reportArn: any
  --nextToken: any
  --maxResults: any
  --sortOrder: any
  --sortBy: any
  --minLineCoveragePercentage: any
  --maxLineCoveragePercentage: any
]: any -> record<nextToken: record, codeCoverages: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DescribeCodeCoverages" $qp)
  let body = {reportArn: $reportArn, nextToken: $nextToken, maxResults: $maxResults, sortOrder: $sortOrder, sortBy: $sortBy, minLineCoveragePercentage: $minLineCoveragePercentage, maxLineCoveragePercentage: $maxLineCoveragePercentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Returns a list of details about test cases for a report. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.DescribeTestCases
# operationId: DescribeTestCases
export def "x-amz-target-code-build-20161006describe-test-cases DescribeTestCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-17
  reportArn: any
  --nextToken: any
  --maxResults: any
  --filter: any
]: any -> record<nextToken: record, testCases: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.DescribeTestCases" $qp)
  let body = {reportArn: $reportArn, nextToken: $nextToken, maxResults: $maxResults, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Analyzes and accumulates test report values for the specified test reports.
#
# POST /#X-Amz-Target=CodeBuild_20161006.GetReportGroupTrend
# operationId: GetReportGroupTrend
export def "x-amz-target-code-build-20161006get-report-group-trend GetReportGroupTrend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-18
  reportGroupArn: any
  --numOfReports: any
  trendField: any
]: any -> record<stats: record<average: record, max: record, min: record>, rawData: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.GetReportGroupTrend")
  let body = {reportGroupArn: $reportGroupArn, numOfReports: $numOfReports, trendField: $trendField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Gets a resource policy that is identified by its resource ARN. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.GetResourcePolicy
# operationId: GetResourcePolicy
export def "x-amz-target-code-build-20161006get-resource-policy GetResourcePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-19
  resourceArn: any
]: any -> record<policy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.GetResourcePolicy")
  let body = {resourceArn: $resourceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Imports the source repository credentials for an CodeBuild project that has its source code stored in a GitHub, GitHub Enterprise, or Bitbucket repository. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials
# operationId: ImportSourceCredentials
export def "x-amz-target-code-build-20161006import-source-credentials ImportSourceCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-20
  --username: any
  --body-token: any
  serverType: any
  authType: any
  --shouldOverwrite: any
]: any -> record<arn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ImportSourceCredentials")
  let body = {username: $username, token: $body_token, serverType: $serverType, authType: $authType, shouldOverwrite: $shouldOverwrite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resets the cache for a project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache
# operationId: InvalidateProjectCache
export def "x-amz-target-code-build-20161006invalidate-project-cache InvalidateProjectCache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-21
  projectName: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.InvalidateProjectCache")
  let body = {projectName: $projectName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the identifiers of your build batches in the current region.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuildBatches
# operationId: ListBuildBatches
export def "x-amz-target-code-build-20161006list-build-batches ListBuildBatches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-22
  --filter: any
  --maxResults: any
  --sortOrder: any
  --nextToken: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuildBatches" $qp)
  let body = {filter: $filter, maxResults: $maxResults, sortOrder: $sortOrder, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the identifiers of the build batches for a specific project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuildBatchesForProject
# operationId: ListBuildBatchesForProject
export def "x-amz-target-code-build-20161006list-build-batches-for-project ListBuildBatchesForProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-23
  --projectName: any
  --filter: any
  --maxResults: any
  --sortOrder: any
  --nextToken: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuildBatchesForProject" $qp)
  let body = {projectName: $projectName, filter: $filter, maxResults: $maxResults, sortOrder: $sortOrder, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of build IDs, with each build ID representing a single build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuilds
# operationId: ListBuilds
export def "x-amz-target-code-build-20161006list-builds ListBuilds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-24
  --sortOrder: any
  --nextToken: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuilds" $qp)
  let body = {sortOrder: $sortOrder, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of build identifiers for the specified build project, with each build identifier representing a single build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject
# operationId: ListBuildsForProject
export def "x-amz-target-code-build-20161006list-builds-for-project ListBuildsForProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-25
  projectName: any
  --sortOrder: any
  --nextToken: any
]: any -> record<ids: record, nextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListBuildsForProject" $qp)
  let body = {projectName: $projectName, sortOrder: $sortOrder, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets information about Docker images that are managed by CodeBuild.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages
# operationId: ListCuratedEnvironmentImages
export def "x-amz-target-code-build-20161006list-curated-environment-images ListCuratedEnvironmentImages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-26
  --body: record
]: any -> record<platforms: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListCuratedEnvironmentImages")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of build project names, with each build project name representing a single build project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListProjects
# operationId: ListProjects
export def "x-amz-target-code-build-20161006list-projects ListProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-27
  --sortBy: any
  --sortOrder: any
  --nextToken: any
]: any -> record<nextToken: record, projects: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListProjects" $qp)
  let body = {sortBy: $sortBy, sortOrder: $sortOrder, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Gets a list ARNs for the report groups in the current Amazon Web Services account. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListReportGroups
# operationId: ListReportGroups
export def "x-amz-target-code-build-20161006list-report-groups ListReportGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-28
  --sortOrder: any
  --sortBy: any
  --nextToken: any
  --maxResults: any
]: any -> record<nextToken: record, reportGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListReportGroups" $qp)
  let body = {sortOrder: $sortOrder, sortBy: $sortBy, nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Returns a list of ARNs for the reports in the current Amazon Web Services account. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListReports
# operationId: ListReports
export def "x-amz-target-code-build-20161006list-reports ListReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-29
  --sortOrder: any
  --nextToken: any
  --maxResults: any
  --filter: any
]: any -> record<nextToken: record, reports: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListReports" $qp)
  let body = {sortOrder: $sortOrder, nextToken: $nextToken, maxResults: $maxResults, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Returns a list of ARNs for the reports that belong to a <code>ReportGroup</code>. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListReportsForReportGroup
# operationId: ListReportsForReportGroup
export def "x-amz-target-code-build-20161006list-reports-for-report-group ListReportsForReportGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-30
  reportGroupArn: any
  --nextToken: any
  --sortOrder: any
  --maxResults: any
  --filter: any
]: any -> record<nextToken: record, reports: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListReportsForReportGroup" $qp)
  let body = {reportGroupArn: $reportGroupArn, nextToken: $nextToken, sortOrder: $sortOrder, maxResults: $maxResults, filter: $filter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Gets a list of projects that are shared with other Amazon Web Services accounts or users. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListSharedProjects
# operationId: ListSharedProjects
export def "x-amz-target-code-build-20161006list-shared-projects ListSharedProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-31
  --sortBy: any
  --sortOrder: any
  --maxResults: any
  --nextToken: any
]: any -> record<nextToken: record, projects: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListSharedProjects" $qp)
  let body = {sortBy: $sortBy, sortOrder: $sortOrder, maxResults: $maxResults, nextToken: $nextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Gets a list of report groups that are shared with other Amazon Web Services accounts or users. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListSharedReportGroups
# operationId: ListSharedReportGroups
export def "x-amz-target-code-build-20161006list-shared-report-groups ListSharedReportGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxResults: string # Pagination limit
  --nextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-32
  --sortOrder: any
  --sortBy: any
  --nextToken: any
  --maxResults: any
]: any -> record<nextToken: record, reportGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "nextToken" $nextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListSharedReportGroups" $qp)
  let body = {sortOrder: $sortOrder, sortBy: $sortBy, nextToken: $nextToken, maxResults: $maxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Returns a list of <code>SourceCredentialsInfo</code> objects. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials
# operationId: ListSourceCredentials
export def "x-amz-target-code-build-20161006list-source-credentials ListSourceCredentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-33
  --body: record
]: any -> record<sourceCredentialsInfos: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.ListSourceCredentials")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Stores a resource policy for the ARN of a <code>Project</code> or <code>ReportGroup</code> object. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.PutResourcePolicy
# operationId: PutResourcePolicy
export def "x-amz-target-code-build-20161006put-resource-policy PutResourcePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-34
  policy: any
  resourceArn: any
]: any -> record<resourceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.PutResourcePolicy")
  let body = {policy: $policy, resourceArn: $resourceArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restarts a build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.RetryBuild
# operationId: RetryBuild
export def "x-amz-target-code-build-20161006retry-build RetryBuild" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-35
  --id: any
]: any -> record<build: record<id: record, arn: record, buildNumber: record, startTime: record, endTime: record, currentPhase: record, buildStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logs: record<groupName: record, streamName: record, deepLink: record, s3DeepLink: record, cloudWatchLogsArn: record, s3LogsArn: record, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: record, queuedTimeoutInMinutes: record, buildComplete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, networkInterface: record<subnetId: record, networkInterfaceId: record>, encryptionKey: record, exportedEnvironmentVariables: record, reportArns: record, fileSystemLocations: record, debugSession: record<sessionEnabled: record, sessionTarget: record>, buildBatchArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.RetryBuild")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restarts a failed batch build. Only batch builds that have failed can be retried.
#
# POST /#X-Amz-Target=CodeBuild_20161006.RetryBuildBatch
# operationId: RetryBuildBatch
export def "x-amz-target-code-build-20161006retry-build-batch RetryBuildBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-36
  --id: any
  --retryType: any
]: any -> record<buildBatch: record<id: record, arn: record, startTime: record, endTime: record, currentPhase: record, buildBatchStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: record, queuedTimeoutInMinutes: record, complete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, encryptionKey: record, buildBatchNumber: record, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, buildGroups: record, debugSessionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.RetryBuildBatch")
  let body = {id: $id, retryType: $retryType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Starts running a build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StartBuild
# operationId: StartBuild
export def "x-amz-target-code-build-20161006start-build StartBuild" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-37
  projectName: any
  --secondarySourcesOverride: any
  --secondarySourcesVersionOverride: any
  --sourceVersion: any
  --artifactsOverride: any
  --secondaryArtifactsOverride: any
  --environmentVariablesOverride: any
  --sourceTypeOverride: any
  --sourceLocationOverride: any
  --sourceAuthOverride: any
  --gitCloneDepthOverride: any
  --gitSubmodulesConfigOverride: any
  --buildspecOverride: any
  --insecureSslOverride: any
  --reportBuildStatusOverride: any
  --buildStatusConfigOverride: any
  --environmentTypeOverride: any
  --imageOverride: any
  --computeTypeOverride: any
  --certificateOverride: any
  --cacheOverride: any
  --serviceRoleOverride: any
  --privilegedModeOverride: any
  --timeoutInMinutesOverride: any
  --queuedTimeoutInMinutesOverride: any
  --encryptionKeyOverride: any
  --logsConfigOverride: any
  --registryCredentialOverride: any
  --imagePullCredentialsTypeOverride: any
  --debugSessionEnabled: any
]: any -> record<build: record<id: record, arn: record, buildNumber: record, startTime: record, endTime: record, currentPhase: record, buildStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logs: record<groupName: record, streamName: record, deepLink: record, s3DeepLink: record, cloudWatchLogsArn: record, s3LogsArn: record, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: record, queuedTimeoutInMinutes: record, buildComplete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, networkInterface: record<subnetId: record, networkInterfaceId: record>, encryptionKey: record, exportedEnvironmentVariables: record, reportArns: record, fileSystemLocations: record, debugSession: record<sessionEnabled: record, sessionTarget: record>, buildBatchArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StartBuild")
  let body = {projectName: $projectName, secondarySourcesOverride: $secondarySourcesOverride, secondarySourcesVersionOverride: $secondarySourcesVersionOverride, sourceVersion: $sourceVersion, artifactsOverride: $artifactsOverride, secondaryArtifactsOverride: $secondaryArtifactsOverride, environmentVariablesOverride: $environmentVariablesOverride, sourceTypeOverride: $sourceTypeOverride, sourceLocationOverride: $sourceLocationOverride, sourceAuthOverride: $sourceAuthOverride, gitCloneDepthOverride: $gitCloneDepthOverride, gitSubmodulesConfigOverride: $gitSubmodulesConfigOverride, buildspecOverride: $buildspecOverride, insecureSslOverride: $insecureSslOverride, reportBuildStatusOverride: $reportBuildStatusOverride, buildStatusConfigOverride: $buildStatusConfigOverride, environmentTypeOverride: $environmentTypeOverride, imageOverride: $imageOverride, computeTypeOverride: $computeTypeOverride, certificateOverride: $certificateOverride, cacheOverride: $cacheOverride, serviceRoleOverride: $serviceRoleOverride, privilegedModeOverride: $privilegedModeOverride, timeoutInMinutesOverride: $timeoutInMinutesOverride, queuedTimeoutInMinutesOverride: $queuedTimeoutInMinutesOverride, encryptionKeyOverride: $encryptionKeyOverride, logsConfigOverride: $logsConfigOverride, registryCredentialOverride: $registryCredentialOverride, imagePullCredentialsTypeOverride: $imagePullCredentialsTypeOverride, debugSessionEnabled: $debugSessionEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Starts a batch build for a project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StartBuildBatch
# operationId: StartBuildBatch
export def "x-amz-target-code-build-20161006start-build-batch StartBuildBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-38
  projectName: any
  --secondarySourcesOverride: any
  --secondarySourcesVersionOverride: any
  --sourceVersion: any
  --artifactsOverride: any
  --secondaryArtifactsOverride: any
  --environmentVariablesOverride: any
  --sourceTypeOverride: any
  --sourceLocationOverride: any
  --sourceAuthOverride: any
  --gitCloneDepthOverride: any
  --gitSubmodulesConfigOverride: any
  --buildspecOverride: any
  --insecureSslOverride: any
  --reportBuildBatchStatusOverride: any
  --environmentTypeOverride: any
  --imageOverride: any
  --computeTypeOverride: any
  --certificateOverride: any
  --cacheOverride: any
  --serviceRoleOverride: any
  --privilegedModeOverride: any
  --buildTimeoutInMinutesOverride: any
  --queuedTimeoutInMinutesOverride: any
  --encryptionKeyOverride: any
  --logsConfigOverride: any
  --registryCredentialOverride: any
  --imagePullCredentialsTypeOverride: any
  --buildBatchConfigOverride: any
  --debugSessionEnabled: any
]: any -> record<buildBatch: record<id: record, arn: record, startTime: record, endTime: record, currentPhase: record, buildBatchStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: record, queuedTimeoutInMinutes: record, complete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, encryptionKey: record, buildBatchNumber: record, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, buildGroups: record, debugSessionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StartBuildBatch")
  let body = {projectName: $projectName, secondarySourcesOverride: $secondarySourcesOverride, secondarySourcesVersionOverride: $secondarySourcesVersionOverride, sourceVersion: $sourceVersion, artifactsOverride: $artifactsOverride, secondaryArtifactsOverride: $secondaryArtifactsOverride, environmentVariablesOverride: $environmentVariablesOverride, sourceTypeOverride: $sourceTypeOverride, sourceLocationOverride: $sourceLocationOverride, sourceAuthOverride: $sourceAuthOverride, gitCloneDepthOverride: $gitCloneDepthOverride, gitSubmodulesConfigOverride: $gitSubmodulesConfigOverride, buildspecOverride: $buildspecOverride, insecureSslOverride: $insecureSslOverride, reportBuildBatchStatusOverride: $reportBuildBatchStatusOverride, environmentTypeOverride: $environmentTypeOverride, imageOverride: $imageOverride, computeTypeOverride: $computeTypeOverride, certificateOverride: $certificateOverride, cacheOverride: $cacheOverride, serviceRoleOverride: $serviceRoleOverride, privilegedModeOverride: $privilegedModeOverride, buildTimeoutInMinutesOverride: $buildTimeoutInMinutesOverride, queuedTimeoutInMinutesOverride: $queuedTimeoutInMinutesOverride, encryptionKeyOverride: $encryptionKeyOverride, logsConfigOverride: $logsConfigOverride, registryCredentialOverride: $registryCredentialOverride, imagePullCredentialsTypeOverride: $imagePullCredentialsTypeOverride, buildBatchConfigOverride: $buildBatchConfigOverride, debugSessionEnabled: $debugSessionEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attempts to stop running a build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StopBuild
# operationId: StopBuild
export def "x-amz-target-code-build-20161006stop-build StopBuild" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-39
  id: any
]: any -> record<build: record<id: record, arn: record, buildNumber: record, startTime: record, endTime: record, currentPhase: record, buildStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logs: record<groupName: record, streamName: record, deepLink: record, s3DeepLink: record, cloudWatchLogsArn: record, s3LogsArn: record, cloudWatchLogs: record, s3Logs: record>, timeoutInMinutes: record, queuedTimeoutInMinutes: record, buildComplete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, networkInterface: record<subnetId: record, networkInterfaceId: record>, encryptionKey: record, exportedEnvironmentVariables: record, reportArns: record, fileSystemLocations: record, debugSession: record<sessionEnabled: record, sessionTarget: record>, buildBatchArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StopBuild")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stops a running batch build.
#
# POST /#X-Amz-Target=CodeBuild_20161006.StopBuildBatch
# operationId: StopBuildBatch
export def "x-amz-target-code-build-20161006stop-build-batch StopBuildBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-40
  id: any
]: any -> record<buildBatch: record<id: record, arn: record, startTime: record, endTime: record, currentPhase: record, buildBatchStatus: record, sourceVersion: record, resolvedSourceVersion: record, projectName: record, phases: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, secondarySourceVersions: record, artifacts: record<location: record, sha256sum: record, md5sum: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, logConfig: record<cloudWatchLogs: record, s3Logs: record>, buildTimeoutInMinutes: record, queuedTimeoutInMinutes: record, complete: record, initiator: record, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, encryptionKey: record, buildBatchNumber: record, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, buildGroups: record, debugSessionEnabled: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.StopBuildBatch")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Changes the settings of a build project.
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateProject
# operationId: UpdateProject
# --buildBatchConfig shape: {serviceRole?: any, combineArtifacts?: any, restrictions?: any, timeoutInMins?: any, batchReportMode?: any}
export def "x-amz-target-code-build-20161006update-project UpdateProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-41
  name: any
  --description: any
  --body-source: any
  --secondarySources: any
  --sourceVersion: any
  --secondarySourceVersions: any
  --artifacts: any
  --secondaryArtifacts: any
  --cache: any
  --environment: any
  --serviceRole: any
  --timeoutInMinutes: any
  --queuedTimeoutInMinutes: any
  --encryptionKey: any
  --tags: any
  --vpcConfig: any
  --badgeEnabled: any
  --logsConfig: any
  --fileSystemLocations: any
  --buildBatchConfig: record # Contains configuration information about a batch build project. — shape: {serviceRole?: any, combineArtifacts?: any, restrictions?: any, timeoutInMins?: any, batchReportMode?: any}
  --concurrentBuildLimit: any
]: any -> record<project: record<name: record, arn: record, description: record, source: record<type: record, location: record, gitCloneDepth: record, gitSubmodulesConfig: record, buildspec: record, auth: record, reportBuildStatus: record, buildStatusConfig: record, insecureSsl: record, sourceIdentifier: record>, secondarySources: record, sourceVersion: record, secondarySourceVersions: record, artifacts: record<type: record, location: record, path: record, namespaceType: record, name: record, packaging: record, overrideArtifactName: record, encryptionDisabled: record, artifactIdentifier: record, bucketOwnerAccess: string>, secondaryArtifacts: record, cache: record<type: record, location: record, modes: record>, environment: record<type: record, image: record, computeType: record, environmentVariables: record, privilegedMode: record, certificate: record, registryCredential: record, imagePullCredentialsType: record>, serviceRole: record, timeoutInMinutes: record, queuedTimeoutInMinutes: record, encryptionKey: record, tags: record, created: record, lastModified: record, webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>, vpcConfig: record<vpcId: record, subnets: record, securityGroupIds: record>, badge: record<badgeEnabled: record, badgeRequestUrl: record>, logsConfig: record<cloudWatchLogs: record, s3Logs: record>, fileSystemLocations: record, buildBatchConfig: record<serviceRole: record, combineArtifacts: record, restrictions: record, timeoutInMins: record, batchReportMode: record>, concurrentBuildLimit: record, projectVisibility: string, publicProjectAlias: record, resourceAccessRole: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateProject")
  let body = {name: $name, description: $description, source: $body_source, secondarySources: $secondarySources, sourceVersion: $sourceVersion, secondarySourceVersions: $secondarySourceVersions, artifacts: $artifacts, secondaryArtifacts: $secondaryArtifacts, cache: $cache, environment: $environment, serviceRole: $serviceRole, timeoutInMinutes: $timeoutInMinutes, queuedTimeoutInMinutes: $queuedTimeoutInMinutes, encryptionKey: $encryptionKey, tags: $tags, vpcConfig: $vpcConfig, badgeEnabled: $badgeEnabled, logsConfig: $logsConfig, fileSystemLocations: $fileSystemLocations, buildBatchConfig: $buildBatchConfig, concurrentBuildLimit: $concurrentBuildLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p>Changes the public visibility for a project. The project's build results, logs, and artifacts are available to the general public. For more information, see <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/public-builds.html">Public build projects</a> in the <i>CodeBuild User Guide</i>.</p> <important> <p>The following should be kept in mind when making your projects public:</p> <ul> <li> <p>All of a project's build results, logs, and artifacts, including builds that were run when the project was private, are available to the general public.</p> </li> <li> <p>All build logs and artifacts are available to the public. Environment variables, source code, and other sensitive information may have been output to the build logs and artifacts. You must be careful about what information is output to the build logs. Some best practice are:</p> <ul> <li> <p>Do not store sensitive values, especially Amazon Web Services access key IDs and secret access keys, in environment variables. We recommend that you use an Amazon EC2 Systems Manager Parameter Store or Secrets Manager to store sensitive values.</p> </li> <li> <p>Follow <a href="https://docs.aws.amazon.com/codebuild/latest/userguide/webhooks.html#webhook-best-practices">Best practices for using webhooks</a> in the <i>CodeBuild User Guide</i> to limit which entities can trigger a build, and do not store the buildspec in the project itself, to ensure that your webhooks are as secure as possible.</p> </li> </ul> </li> <li> <p>A malicious user can use public builds to distribute malicious artifacts. We recommend that you review all pull requests to verify that the pull request is a legitimate change. We also recommend that you validate any artifacts with their checksums to make sure that the correct artifacts are being downloaded.</p> </li> </ul> </important>
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateProjectVisibility
# operationId: UpdateProjectVisibility
export def "x-amz-target-code-build-20161006update-project-visibility UpdateProjectVisibility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-42
  projectArn: any
  projectVisibility: string@projectVisibility-completer # <p>Specifies the visibility of the project's builds. Possible values are:</p> <dl> <dt>PUBLIC_READ</dt> <dd> <p>The project builds are visible to the public.</p> </dd> <dt>PRIVATE</dt> <dd> <p>The project builds are not visible to the public.</p> </dd> </dl>
  --resourceAccessRole: any
]: any -> record<projectArn: record, publicProjectAlias: record, projectVisibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateProjectVisibility")
  let body = {projectArn: $projectArn, projectVisibility: $projectVisibility, resourceAccessRole: $resourceAccessRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

#  Updates a report group. 
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateReportGroup
# operationId: UpdateReportGroup
export def "x-amz-target-code-build-20161006update-report-group UpdateReportGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-43
  arn: any
  --exportConfig: any
  --tags: any
]: any -> record<reportGroup: record<arn: record, name: record, type: record, exportConfig: record<exportConfigType: record, s3Destination: record>, created: record, lastModified: record, tags: record, status: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateReportGroup")
  let body = {arn: $arn, exportConfig: $exportConfig, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <p> Updates the webhook associated with an CodeBuild build project. </p> <note> <p> If you use Bitbucket for your repository, <code>rotateSecret</code> is ignored. </p> </note>
#
# POST /#X-Amz-Target=CodeBuild_20161006.UpdateWebhook
# operationId: UpdateWebhook
export def "x-amz-target-code-build-20161006update-webhook UpdateWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-44
  projectName: any
  --branchFilter: any
  --rotateSecret: any
  --filterGroups: any
  --buildType: any
]: any -> record<webhook: record<url: record, payloadUrl: record, secret: record, branchFilter: record, filterGroups: record, buildType: record, lastModifiedSecret: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=CodeBuild_20161006.UpdateWebhook")
  let body = {projectName: $projectName, branchFilter: $branchFilter, rotateSecret: $rotateSecret, filterGroups: $filterGroups, buildType: $buildType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
