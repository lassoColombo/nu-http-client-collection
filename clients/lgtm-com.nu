# Auto-generated client for LGTM API specification vv1.0
# Source: https://api.apis.guru/v2/specs/lgtm.com/v1.0/openapi.json
# Auth: --token flag or $env.LGTM_API_SPECIFICATION_TOKEN

const BASE_URL = "https://lgtm.com/api/v1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LGTM_API_SPECIFICATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://lgtm.com/api/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/sarif+json" "text/csv"] }
def mode-completer [] { ["full" "sparse" "upload"] }
def source-completer [] { ["administrator" "repository"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-root get-version" } } | get name | first)
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

# Version information
#
# GET /
# operationId: getVersion
export def "api-root get-version" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get analysis summary
#
# GET /analyses/{analysis-id}
# operationId: getAnalysis
export def "analyses get" [
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit_id: string, id: string, languages: table<alerts: int, analysis_date: string, commit_date: string, commit_id: string, language: string, lines: int, status: string>, log_url: string, project: record<id: int, name: string, url: string, url_identifier: string>, results_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({analysis_id: (encode-path-segment $analysis_id)} | format pattern "/analyses/{analysis_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detailed alert information
#
# GET /analyses/{analysis-id}/alerts
# operationId: getAlerts
export def "analyses-alerts get" [
  analysis_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sarif-version: string # The desired version of the SARIF format. Currently supported versions are `1.0.0`, `2.0.0`, and `2.1.0`.
  --excluded-files: oneof<nothing, bool> # Set `true` to include results in files that are excluded from the output by default. This includes results in test code and generated files. For more information, see [File classification](https://lgtm.com/help/lgtm/file-classification). (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sarif-version" $sarif_version "scalar") (serialize-qp "excluded-files" $excluded_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({analysis_id: (encode-path-segment $analysis_id)} | format pattern "/analyses/{analysis_id}/alerts") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run analysis of a specific commit
#
# POST /analyses/{project-id}
# operationId: requestAnalysis
export def "analyses request-analysis" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit: string # The identifier of the commit to analyze.
  --language: list<string> # The language codes of the languages to analyze. For a list of available languages, see [Supported languages](https://lgtm.com/help/lgtm/analysis-faqs#which-languages-are-supported). To specify more than one language, this parameter can be repeated. If no language is specified, all the project's languages will be analyzed.
]: nothing -> record<id: int, status: string, task_result: any, task_result_url: string, task_type: string, uploads: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "commit" $commit "scalar") (serialize-qp "language" $language "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/analyses/{project_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get analysis summary for a specific commit
#
# GET /analyses/{project-id}/commits/{commit-id}
# operationId: getAnalysisForCommit
export def "analyses-commits get-analysis" [
  project_id: int
  commit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit_id: string, id: string, languages: table<alerts: int, analysis_date: string, commit_date: string, commit_id: string, language: string, lines: int, status: string>, log_url: string, project: record<id: int, name: string, url: string, url_identifier: string>, results_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), commit_id: (encode-path-segment $commit_id)} | format pattern "/analyses/{project_id}/commits/{commit_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run code review for a patch
#
# POST /codereviews/{project-id}
# operationId: requestReview
export def "codereviews request-review" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-base: string # The identifier for the base commit.
  --external-id: int # Your reference number for the code review. (format: int32, e.g. integer)
  --review-url: string # An informative back-link to an external system.
  --callback-url: string # The callback URL for LGTM to post to on completion of the review. When the code review is complete, the API sends an HTTP POST request to the callback URL with the result of the code review in the request body. The code review results in the request body are identical to the results accessed through the [`/codereviews/{review-id}`](https://lgtm.com/help/lgtm/api/api-v1#opIdgetCodeReview) end-point. If you specify a `callback-secret`, the request also includes an `x-lgtm-signature` header with a digital signature of the request's contents.
  --callback-secret: string # The `callback-secret` is used to compute a signature which is included in the `x-lgtm-signature` header of the callback response. The receiver of the callback can check the validity of the response by computing the signature using HMAC-SHA1 and verifying that it matches the `x-lgtm-signature` header value. The HMAC algorithm requires byte sequences as inputs for both the secret and the message. The callback secret string must be converted to bytes using UTF-8 encoding. The response body should ideally be read as a plain byte sequence. Conversion to, for example a JSON object, and back to a byte sequence might change the formatting, and would invalidate the signature.
  --body: record
]: any -> record<id: int, status: string, task_result: any, task_result_url: string, task_type: string, uploads: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "external-id" $external_id "scalar") (serialize-qp "review-url" $review_url "scalar") (serialize-qp "callback-url" $callback_url "scalar") (serialize-qp "callback-secret" $callback_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/codereviews/{project_id}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $req_body
}

# Get results of code review
#
# GET /codereviews/{review-id}
# operationId: getCodeReview
export def "codereviews get-code" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, languages: list<record>, results_url: string, status: string, status_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/codereviews/{review_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detailed alert information for an issue
#
# GET /issues/{project-id}/{alert-key}
# operationId: getIssue
export def "issues get" [
  project_id: int
  alert_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), alert_key: (encode-path-segment $alert_key)} | format pattern "/issues/{project_id}/{alert_key}"))
  let accept_val = "application/sarif+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# API specification
#
# GET /openapi
# operationId: getSpec
export def "openapi get-spec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/openapi")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get operation status
#
# GET /operations/{operation-id}
# operationId: getOperation
export def "operations get" [
  operation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, status: string, task_result: any, task_result_url: string, task_type: string, uploads: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({operation_id: (encode-path-segment $operation_id)} | format pattern "/operations/{operation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List projects
#
# GET /projects
# operationId: getProjects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of projects to return in each response (1-100). (format: int32, default: 100)
  --start: string # An opaque identifier generated by the API.
]: nothing -> record<data: table<id: int, name: string, url: string, url_identifier: string>, nextPageUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a project to LGTM
#
# POST /projects
# operationId: addProject
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --repository: string # The URL of the repository to analyze. LGTM tests this against the [repository providers](https://lgtm.com/admin/help/adding-repository-providers) defined for the system. If it doesn't match any of them, the request fails. (format: uri)
  --language: list<string> # Optional, a [language code](https://lgtm.com/help/lgtm/analysis-faqs#which-languages-are-supported) to specify which language to analyze. To request the analysis of more than one language, specify a query parameter for each language. By default, LGTM tries to analyze all supported languages.
  --mode: string@mode-completer # The analysis mode of the new project. When set to `full` all commits of the project are analyzed; when set to `sparse` the latest commit of the project is analyzed periodically; when set to `upload`, no automatic analysis is performed, instead externally-generated databases should be uploaded. For new projects the default value is `full`. The `mode` parameter cannot be used to change the analysis mode of existing projects. Therefore, for existing projects, it should either be left blank or set to match the analysis mode of the project.
  --commit: string # Required when `mode=upload`, specify the identifier of the commit used to generate the database.
  --date: string # Optional when `mode=upload`, specify the date and time of the commit used to generate the database; defaults to the current time. (format: date-time)
  --worker-label: list<string> # Optional, any [labels](https://lgtm.com/admin/help/defining-worker-labels) required by workers to analyze this project. To specify more than one label, repeat the query parameter.
  --body: record
]: any -> record<id: int, status: string, task_result: any, task_result_url: string, task_type: string, uploads: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repository" $repository "scalar") (serialize-qp "language" $language "multi") (serialize-qp "mode" $mode "scalar") (serialize-qp "commit" $commit "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "worker-label" $worker_label "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $req_body
}

# Delete project by numeric identifier
#
# DELETE /projects/{project-id}
# operationId: deleteProject
export def "projects delete" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, url: string, url_identifier: string, languages: table<alerts: int, analysis_date: string, commit_date: string, commit_id: string, language: string, lines: int, status: string, grade: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project by numeric identifier
#
# GET /projects/{project-id}
# operationId: getProject
export def "projects get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, url: string, url_identifier: string, languages: table<alerts: int, analysis_date: string, commit_date: string, commit_id: string, language: string, lines: int, status: string, grade: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configuration for a project identified by numeric identifier
#
# GET /projects/{project-id}/settings/analysis-configuration
# operationId: getProjectConfig
export def "projects-settings-analysis-configuration get-config" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-source: string@source-completer # The type of project configuration to retrieve. If this parameter isn't specified, the request retrieves the effective configuration. That is, the configuration that is actually applied to the project, which may be from: * the repository * the administrator-set, project configuration * the global configuration. If you do specify this value, it must be one of: * `repository` to retrieve the configuration specified by a YAML file in the repository. A 404 status is returned if there is no repository configuration. * `administrator` to retrieve the administrator-set, project configuration. A 404 status is returned if there is no administrator configuration.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/settings/analysis-configuration") $qp)
  let accept_val = "application/x-yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the administrator configuration for a project identified by numeric identifier
#
# PUT /projects/{project-id}/settings/analysis-configuration
# operationId: setProjectConfig
export def "projects-settings-analysis-configuration update-config" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/settings/analysis-configuration"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/x-yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-yaml" $req_body
}

# Get project by URL identifier
#
# GET /projects/{provider}/{org}/{name}
# operationId: getProjectByUrlIdentifier
export def "projects get-by-url-identifier" [
  provider: string
  org: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, url: string, url_identifier: string, languages: table<alerts: int, analysis_date: string, commit_date: string, commit_id: string, language: string, lines: int, status: string, grade: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider: (encode-path-segment $provider), org: (encode-path-segment $org), name: (encode-path-segment $name)} | format pattern "/projects/{provider}/{org}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a CodeQL query on one or more projects
#
# POST /queryjobs
# operationId: createQueryJob
export def "queryjobs create-list-job" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [language](https://lgtm.com/help/lgtm/analysis-faqs#which-languages-are-supported) you want to analyze.
  --project-id: list<int> # The identifier of the project to analyze. Either `project-id` or `projects-list` must be specified.
  --projects-list: string # Name of the list containing the projects to analyze. Either `project-id` or `projects-list` must be specified.
  --body: record
]: any -> record<id: int, status: string, task_result: any, task_result_url: string, task_type: string, uploads: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "project-id" $project_id "multi") (serialize-qp "projects-list" $projects_list "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/queryjobs" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $req_body
}

# Get the status of a query job
#
# GET /queryjobs/{queryjob-id}
# operationId: getQueryJob
export def "queryjobs get-list-job" [
  queryjob_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, result_url: string, stats: record<failed: int, pending: int, success_with_result: int, success_without_result: int, successful: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({queryjob_id: (encode-path-segment $queryjob_id)} | format pattern "/queryjobs/{queryjob_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provide a summary of results for the projects in the query job
#
# GET /queryjobs/{queryjob-id}/results
# operationId: getQueryJobResultsOverview
export def "queryjobs-results get-list-job-overview" [
  queryjob_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # An opaque identifier generated by the API used for pagination. This identifier will be included as part of the response for this endpoint whenever more than one page of results is available.
  --limit: int # The number of results to return. Useful for pagination. (format: int32, default: 100)
  --filter: string # Only return a subset of results. Legal values are `w-results`, `wo-results`, `error`.
]: nothing -> record<data: table<error: string, external: int, internal: int, project: record, status: string, total: int>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({queryjob_id: (encode-path-segment $queryjob_id)} | format pattern "/queryjobs/{queryjob_id}/results") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the results of a query job for a specific project
#
# GET /queryjobs/{queryjob-id}/results/{project-id}
# operationId: getQueryJobResultsForProject
export def "queryjobs-results get-list-job" [
  queryjob_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Start point for the page of results. (format: int32)
  --limit: int # The maximum number of results to display (less than 100). (format: int32, default: 100)
  --nofilter: oneof<nothing, bool> # Include results that are not part of the source tree. These results are filtered out by default. (default: false)
]: nothing -> record<columns: list<string>, data: list<list<record>>, next: string, project: record<id: int, name: string, url: string, url_identifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nofilter" $nofilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({queryjob_id: (encode-path-segment $queryjob_id), project_id: (encode-path-segment $project_id)} | format pattern "/queryjobs/{queryjob_id}/results/{project_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abort database upload process
#
# DELETE /snapshots/uploads/{session-id}
# operationId: abortUpload
export def "snapshots-uploads abort" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, status: string, task_result: any, task_result_url: string, task_type: string, uploads: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/snapshots/uploads/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete snapshot upload session
#
# POST /snapshots/uploads/{session-id}
# operationId: completeUpload
export def "snapshots-uploads complete" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, status: string, task_result: any, task_result_url: string, task_type: string, uploads: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/snapshots/uploads/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload snapshot
#
# PUT /snapshots/uploads/{session-id}
# operationId: uploadPart
export def "snapshots-uploads upload-part" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/snapshots/uploads/{session_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $req_body
}

# Download a snapshot
#
# GET /snapshots/{project-id}/{language}
# operationId: getSnapshot
export def "snapshots get" [
  project_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), language: (encode-path-segment $language)} | format pattern "/snapshots/{project_id}/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start snapshot upload session
#
# POST /snapshots/{project-id}/{language}
# operationId: initSnapshotUpload
export def "snapshots upload-init" [
  project_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit: string # The identifier of the analyzed commit.
  --date: string # The date and time of the analyzed commit (default the current time). (format: date-time)
]: nothing -> record<id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "commit" $commit "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), language: (encode-path-segment $language)} | format pattern "/snapshots/{project_id}/{language}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a summary of the application's health
#
# GET /system/health
# operationId: getHealth
export def "system-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, details: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the identifiers and descriptions of the usage metrics
#
# GET /system/metrics
# operationId: getMetrics
export def "system-metrics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<description: string, metric_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the computed values of the specified metric
#
# GET /system/metrics/{metric-id}
# operationId: getMetric
export def "system-metrics get" [
  metric_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<measurements: table<timestamp: string, value: float>, metric_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({metric_id: (encode-path-segment $metric_id)} | format pattern "/system/metrics/{metric_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
