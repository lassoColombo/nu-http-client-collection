# Auto-generated client for CircleCI REST API vv1
# Source: https://api.apis.guru/v2/specs/circleci.com/v1/openapi.json
# Auth: --token flag or $env.CIRCLECI_REST_API_TOKEN

const BASE_URL = "https://circleci.com/api/v1"
const DEFAULT_AUTH = "query-circle-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CIRCLECI_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-circle-token" => { {headers: {}, query: $"circle-token=($token_val)"} }
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

def base-url-completer [] { ["https://circleci.com/api/v1"] }
def auth-scheme-completer [] { ["query-circle-token"] }

# Completers for enum parameters
def filter-completer [] { ["completed" "failed" "running" "successful"] }
def Content-Type-completer [] { ["application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
]: nothing -> record<admin: bool, all_emails: list<string>, analytics_id: string, avatar_url: string, basic_email_prefs: string, bitbucket: int, bitbucket_authorized: bool, containers: int, created_at: string, days_left_in_trial: int, dev_admin: bool, enrolled_betas: list<string>, github_id: int, github_oauth_scopes: list<string>, gravatar_id: int, heroku_api_key: string, in_beta_program: bool, login: string, name: string, organization_prefs: record, parallelism: int, plan: string, projects: record, pusher_id: string, selected_email: string, sign_in_count: int, trial_end: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # The number of builds to return. Maximum 100, defaults to 30.  (default: 30)
  --offset: int # The API returns builds starting from this offset, defaults to 0.  (default: 0)
  --filter: string@filter-completer # Restricts which builds are returned. Set to "completed", "successful", "failed", "running", or defaults to no filter.
]: nothing -> table<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/project/($username)/($project)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Triggers a new build, returns a summary of the build.
#
# POST /project/{username}/{project}
export def "project post" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --build-parameters: record # Additional environment variables to inject into the build environment. A map of names to values.
  --parallel: string # The number of containers to use to run the build. Default is null and the project default is used.
  --revision: string # The specific revision to build. Default is null and the head of the branch is used. Cannot be used with tag parameter.
  --tag: string # The tag to build. Default is null. Cannot be used with revision parameter.
]: any -> record<added_at: string, build_num: int, outcome: string, pushed_at: string, status: string, vcs_revision: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)")
  let body = {build_parameters: $build_parameters, parallel: $parallel, revision: $revision, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/build-cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<fingerprint: string, preferred: bool, public_key: string, time: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/checkout-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new checkout key. Only usable with a user API token.
#
# POST /project/{username}/{project}/checkout-key
export def "project-checkout-key post" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/checkout-key")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/checkout-key/($fingerprint)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/checkout-key/($fingerprint)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/envvar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new environment variable
#
# POST /project/{username}/{project}/envvar
export def "project-envvar post" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/envvar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/envvar/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/envvar/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an ssh key used to access external systems that require SSH key-based authentication
#
# POST /project/{username}/{project}/ssh-key
export def "project-ssh-key post" [
  username: string
  project: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string@Content-Type-completer
  --hostname: string
  --private-key: string
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/ssh-key")
  let body = {hostname: $hostname, private_key: $private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Triggers a new build, returns a summary of the build. Optional build parameters can be set using an experimental API.  Note: For more about build parameters, read about [using parameterized builds](https://circleci.com/docs/parameterized-builds/)
#
# POST /project/{username}/{project}/tree/{branch}
export def "project-tree post" [
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
  --build-parameters: record # Additional environment variables to inject into the build environment. A map of names to values.
  --parallel: string # The number of containers to use to run the build. Default is null and the project default is used.
  --revision: string # The specific revision to build. Default is null and the head of the branch is used. Cannot be used with tag parameter.
]: any -> record<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/tree/($branch)")
  let body = {build_parameters: $build_parameters, parallel: $parallel, revision: $revision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<all_commit_details: table<author_date: string, author_email: string, author_login: string, author_name: string, body: string, commit: string, commit_url: string, committer_date: string, committer_email: string, committer_login: string, committer_name: string, subject: string>, compare: string, job_name: string, node: any, previous_successful_build: record<build_num: int, build_time_millis: int, status: string>, retries: bool, ssh_enabled: bool, timedout: bool, usage_queued_at: string, user: record<admin: bool, all_emails: list<string>, analytics_id: string, avatar_url: string, basic_email_prefs: string, bitbucket: int, bitbucket_authorized: bool, containers: int, created_at: string, days_left_in_trial: int, dev_admin: bool, enrolled_betas: list<string>, github_id: int, github_oauth_scopes: list<string>, gravatar_id: int, heroku_api_key: string, in_beta_program: bool, login: string, name: string, organization_prefs: record, parallelism: int, plan: string, projects: record, pusher_id: string, selected_email: string, sign_in_count: int, trial_end: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/($build_num)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<node_index: int, path: string, pretty_path: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/($build_num)/artifacts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels the build, returns a summary of the build.
#
# POST /project/{username}/{project}/{build_num}/cancel
export def "project-cancel post" [
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
]: nothing -> record<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/($build_num)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retries the build, returns a summary of the new build.
#
# POST /project/{username}/{project}/{build_num}/retry
export def "project-retry post" [
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
]: nothing -> record<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/($build_num)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> record<tests: table<classname: string, file: string, message: string, name: string, result: string, run_time: float, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/project/($username)/($project)/($build_num)/tests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> table<aws: record<keypair: string>, branches: record, campfire_notify_prefs: string, campfire_room: string, campfire_subdomain: string, campfire_token: string, compile: string, default_branch: string, dependencies: string, extra: string, feature_flags: record<build_fork_prs: bool, fleet: bool, junit: bool, oss: bool, osx: bool, set_github_status: bool, trusty_beta: bool>, flowdock_api_token: string, followed: bool, has_usable_key: bool, heroku_deploy_user: string, hipchat_api_token: string, hipchat_notify: string, hipchat_notify_prefs: string, hipchat_room: string, irc_channel: string, irc_keyword: string, irc_notify_prefs: string, irc_password: string, irc_server: string, irc_username: string, language: string, oss: bool, parallel: int, reponame: string, scopes: list<string>, setup: string, slack_api_token: string, slack_channel: string, slack_channel_override: string, slack_notify_prefs: string, slack_subdomain: string, slack_webhook_url: string, ssh_keys: list<string>, test: string, username: string, vcs_type: string, vcs_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --limit: int # The number of builds to return. Maximum 100, defaults to 30.  (default: 30)
  --offset: int # The API returns builds starting from this offset, defaults to 0.  (default: 0)
]: nothing -> table<body: string, branch: string, build_time_millis: int, build_url: string, committer_email: string, committer_name: string, dont_build: string, lifecycle: string, previous: record<build_num: int, build_time_millis: int, status: string>, queued_at: string, reponame: string, retry_of: int, start_time: string, stop_time: string, subject: string, username: string, vcs_url: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recent-builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds your Heroku API key to CircleCI, takes apikey as form param name.
#
# POST /user/heroku-key
export def "user-heroku-key post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-circle-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/heroku-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
