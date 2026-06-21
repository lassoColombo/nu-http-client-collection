# Auto-generated client for CircleCI REST API vv1
# Source: https://api.apis.guru/v2/specs/circleci.com/v1/openapi.json
# Auth: --token flag or $env.CIRCLECI_REST_API_TOKEN

const BASE_URL = "https://circleci.com/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CIRCLECI_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-circle-token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "circle-token")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://circleci.com/api/v1"] }
def auth-scheme-completer [] { ["query-circle-token"] }

# Completers for enum parameters
def filter-completer [] { ["completed" "failed" "running" "successful"] }
def content-type-completer [] { ["application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "me get" } } | get name | first)
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

# Provides information about the signed in user.
#
# GET /me
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: bool, all_emails: list<string>, analytics_id: string, avatar_url: string, basic_email_prefs: string, bitbucket: int, bitbucket_authorized: bool, containers: int, created_at: string, days_left_in_trial: int, dev_admin: bool, enrolled_betas: list<string>, github_id: int, github_oauth_scopes: list<string>, gravatar_id: int, heroku_api_key: string, in_beta_program: bool, login: string, name: string, organization_prefs: record, parallelism: int, plan: string, projects: record, pusher_id: string, selected_email: string, sign_in_count: int, trial_end: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Build summary for each of the last 30 builds for a single git repo.
#
# GET /project/{username}/{project}
export def "project list" [
  username: any
  project: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of builds to return. Maximum 100, defaults to 30. (default: 30)
  --offset: int # The API returns builds starting from this offset, defaults to 0. (default: 0)
  --filter: string@filter-completer # Restricts which builds are returned. Set to "completed", "successful", "failed", "running", or defaults to no filter.
]: nothing -> table<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter} | compact), body: null}
}

# Triggers a new build, returns a summary of the build.
#
# POST /project/{username}/{project}
export def "project create" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build-parameters: record # Additional environment variables to inject into the build environment. A map of names to values.
  --parallel: string # The number of containers to use to run the build. Default is null and the project default is used.
  --revision: string # The specific revision to build. Default is null and the head of the branch is used. Cannot be used with tag parameter.
  --tag: string # The tag to build. Default is null. Cannot be used with revision parameter.
]: any -> record<added_at: string, build_num: int, outcome: string, pushed_at: string, status: string, vcs_revision: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}"))
  let req_body = {"build_parameters": $build_parameters, "parallel": $parallel, "revision": $revision, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Clears the cache for a project.
#
# DELETE /project/{username}/{project}/build-cache
export def "project-build-cache delete" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}/build-cache"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists checkout keys.
#
# GET /project/{username}/{project}/checkout-key
export def "project-checkout-key list" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<fingerprint: string, preferred: bool, public_key: string, time: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}/checkout-key"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new checkout key. Only usable with a user API token.
#
# POST /project/{username}/{project}/checkout-key
export def "project-checkout-key create" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}/checkout-key"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a checkout key.
#
# DELETE /project/{username}/{project}/checkout-key/{fingerprint}
export def "project-checkout-key delete" [
  username: string
  project: string
  fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($fingerprint | is-empty) { error make --unspanned { msg: "path parameter 'fingerprint' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), fingerprint: (encode-path-segment $fingerprint)} | format pattern "/project/{username}/{project}/checkout-key/{fingerprint}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a checkout key.
#
# GET /project/{username}/{project}/checkout-key/{fingerprint}
export def "project-checkout-key get" [
  username: string
  project: string
  fingerprint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($fingerprint | is-empty) { error make --unspanned { msg: "path parameter 'fingerprint' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), fingerprint: (encode-path-segment $fingerprint)} | format pattern "/project/{username}/{project}/checkout-key/{fingerprint}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists the environment variables for :project
#
# GET /project/{username}/{project}/envvar
export def "project-envvar list" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}/envvar"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates a new environment variable
#
# POST /project/{username}/{project}/envvar
export def "project-envvar create" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}/envvar"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes the environment variable named ':name'
#
# DELETE /project/{username}/{project}/envvar/{name}
export def "project-envvar delete" [
  username: string
  project: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), name: (encode-path-segment $name)} | format pattern "/project/{username}/{project}/envvar/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the hidden value of environment variable :name
#
# GET /project/{username}/{project}/envvar/{name}
export def "project-envvar get" [
  username: string
  project: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), name: (encode-path-segment $name)} | format pattern "/project/{username}/{project}/envvar/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an ssh key used to access external systems that require SSH key-based authentication
#
# POST /project/{username}/{project}/ssh-key
export def "project-ssh-key create" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string@content-type-completer
  --hostname: string
  --private-key: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project)} | format pattern "/project/{username}/{project}/ssh-key"))
  let req_body = {"hostname": $hostname, "private_key": $private_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Triggers a new build, returns a summary of the build. Optional build parameters can be set using an experimental API. Note: For more about build parameters, read about [using parameterized builds](https://circleci.com/docs/parameterized-builds/)
#
# POST /project/{username}/{project}/tree/{branch}
export def "project-tree create" [
  username: string
  project: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --build-parameters: record # Additional environment variables to inject into the build environment. A map of names to values.
  --parallel: string # The number of containers to use to run the build. Default is null and the project default is used.
  --revision: string # The specific revision to build. Default is null and the head of the branch is used. Cannot be used with tag parameter.
]: any -> record<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($branch | is-empty) { error make --unspanned { msg: "path parameter 'branch' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), branch: (encode-path-segment $branch)} | format pattern "/project/{username}/{project}/tree/{branch}"))
  let req_body = {"build_parameters": $build_parameters, "parallel": $parallel, "revision": $revision} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Full details for a single build. The response includes all of the fields from the build summary. This is also the payload for the [notification webhooks](/docs/configuration/#notify), in which case this object is the value to a key named 'payload'.
#
# GET /project/{username}/{project}/{build_num}
export def "project get" [
  username: string
  project: string
  build_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<all_commit_details: table<author_date: string, author_email: string, author_login: string, author_name: string, body: string, commit: string, commit_url: string, committer_date: string, committer_email: string, committer_login: string, committer_name: string, subject: string>, compare: string, job_name: string, node: any, previous_successful_build: record<build_num: int, build_time_millis: int, status: string>, retries: bool, ssh_enabled: bool, timedout: bool, usage_queued_at: string, user: record<admin: bool, all_emails: list<string>, analytics_id: string, avatar_url: string, basic_email_prefs: string, bitbucket: int, bitbucket_authorized: bool, containers: int, created_at: string, days_left_in_trial: int, dev_admin: bool, enrolled_betas: list<string>, github_id: int, github_oauth_scopes: list<string>, gravatar_id: int, heroku_api_key: string, in_beta_program: bool, login: string, name: string, organization_prefs: record, parallelism: int, plan: string, projects: record, pusher_id: string, selected_email: string, sign_in_count: int, trial_end: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($build_num | is-empty) { error make --unspanned { msg: "path parameter 'build_num' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), build_num: (encode-path-segment $build_num)} | format pattern "/project/{username}/{project}/{build_num}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the artifacts produced by a given build.
#
# GET /project/{username}/{project}/{build_num}/artifacts
export def "project-artifacts get" [
  username: string
  project: string
  build_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<node_index: int, path: string, pretty_path: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($build_num | is-empty) { error make --unspanned { msg: "path parameter 'build_num' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), build_num: (encode-path-segment $build_num)} | format pattern "/project/{username}/{project}/{build_num}/artifacts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancels the build, returns a summary of the build.
#
# POST /project/{username}/{project}/{build_num}/cancel
export def "project-cancel create" [
  username: string
  project: string
  build_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($build_num | is-empty) { error make --unspanned { msg: "path parameter 'build_num' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), build_num: (encode-path-segment $build_num)} | format pattern "/project/{username}/{project}/{build_num}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retries the build, returns a summary of the new build.
#
# POST /project/{username}/{project}/{build_num}/retry
export def "project-retry create" [
  username: string
  project: string
  build_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($build_num | is-empty) { error make --unspanned { msg: "path parameter 'build_num' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), build_num: (encode-path-segment $build_num)} | format pattern "/project/{username}/{project}/{build_num}/retry"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Provides test metadata for a build Note: [Learn how to set up your builds to collect test metadata](https://circleci.com/docs/test-metadata/)
#
# GET /project/{username}/{project}/{build_num}/tests
export def "project-tests get" [
  username: string
  project: string
  build_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tests: table<classname: string, file: string, message: string, name: string, result: string, run_time: float, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project | is-empty) { error make --unspanned { msg: "path parameter 'project' must be non-empty" } }
  if ($build_num | is-empty) { error make --unspanned { msg: "path parameter 'build_num' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project: (encode-path-segment $project), build_num: (encode-path-segment $build_num)} | format pattern "/project/{username}/{project}/{build_num}/tests"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of all the projects you're following on CircleCI, with build information organized by branch.
#
# GET /projects
export def "projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<aws: record<keypair: string>, branches: record, campfire_notify_prefs: string, campfire_room: string, campfire_subdomain: string, campfire_token: string, compile: string, default_branch: string, dependencies: string, extra: string, feature_flags: record<build_fork_prs: bool, fleet: bool, junit: bool, oss: bool, osx: bool, set_github_status: bool, trusty_beta: bool>, flowdock_api_token: string, followed: bool, has_usable_key: bool, heroku_deploy_user: string, hipchat_api_token: string, hipchat_notify: string, hipchat_notify_prefs: string, hipchat_room: string, irc_channel: string, irc_keyword: string, irc_notify_prefs: string, irc_password: string, irc_server: string, irc_username: string, language: string, oss: bool, parallel: int, reponame: string, scopes: list<string>, setup: string, slack_api_token: string, slack_channel: string, slack_channel_override: string, slack_notify_prefs: string, slack_subdomain: string, slack_webhook_url: string, ssh_keys: list<string>, test: string, username: string, vcs_type: string, vcs_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Build summary for each of the last 30 recent builds, ordered by build_num.
#
# GET /recent-builds
export def "recent-builds get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of builds to return. Maximum 100, defaults to 30. (default: 30)
  --offset: int # The API returns builds starting from this offset, defaults to 0. (default: 0)
]: nothing -> table<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recent-builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Adds your Heroku API key to CircleCI, takes apikey as form param name.
#
# POST /user/heroku-key
export def "user-heroku-key create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/heroku-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
