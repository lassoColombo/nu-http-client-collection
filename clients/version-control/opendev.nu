# Auto-generated client for Gitea API vv1.26.2
# Source: https://opendev.org/swagger.v1.json
# Auth: --token flag or $env.GITEA_API_TOKEN

const BASE_URL = "https://localhost/api/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GITEA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-access_token" => { {headers: {}, query: $"access_token=($token_val)"} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "sudo" => { {headers: {Sudo: $token_val}, query: ""} }
    "query-sudo" => { {headers: {}, query: $"sudo=($token_val)"} }
    "x-gitea-otp" => { {headers: {X-GITEA-OTP: $token_val}, query: ""} }
    "query-token" => { {headers: {}, query: $"token=($token_val)"} }
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

def base-url-completer [] { ["https://localhost/api/v1" "http://localhost/api/v1"] }
def auth-scheme-completer [] { ["query-access_token" "bearer" "basic" "sudo" "query-sudo" "x-gitea-otp" "query-token"] }

# Completers for enum parameters
def type-completer [] { ["all" "default" "system"] }
def type-completer-1 [] { ["dingtalk" "discord" "feishu" "gitea" "gogs" "msteams" "packagist" "slack" "telegram" "wechatwork"] }
def visibility-completer [] { ["limited" "private" "public"] }
def object-format-name-completer [] { ["sha1" "sha256"] }
def trust-model-completer [] { ["collaborator" "collaboratorcommitter" "committer" "default"] }
def permission-completer [] { ["admin" "read" "write"] }
def type-completer-2 [] { ["alpine" "cargo" "chef" "composer" "conan" "conda" "container" "cran" "debian" "generic" "go" "helm" "maven" "npm" "nuget" "pub" "pypi" "rpm" "rubygems" "swift" "terraform" "vagrant"] }
def state-completer [] { ["all" "closed" "open"] }
def type-completer-3 [] { ["issues" "pulls"] }
def service-completer [] { ["codebase" "codecommit" "git" "gitbucket" "gitea" "github" "gitlab" "gogs" "onedev"] }
def sort-completer [] { ["highestindex" "leastindex" "leastupdate" "oldest" "recentupdate"] }
def state-completer-1 [] { ["error" "failure" "pending" "success" "warning"] }
def state-completer-2 [] { ["closed" "open"] }
def sort-completer-1 [] { ["leastcomment" "leastupdate" "mostcomment" "oldest" "priority" "recentclose" "recentupdate"] }
def whitespace-completer [] { ["ignore-all" "ignore-change" "ignore-eol" "show-all"] }
def do-completer [] { ["fast-forward-only" "manually-merged" "merge" "rebase" "rebase-merge" "squash"] }
def event-completer [] { ["APPROVED" "COMMENT" "PENDING" "REQUEST_CHANGES" "REQUEST_REVIEW"] }
def style-completer [] { ["merge" "rebase"] }
def state-completer-3 [] { ["error" "failure" "pending" "skipped" "success" "warning"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-actions-jobs listAdminWorkflowJobs" } } | get name | first)
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

# Lists all jobs
#
# GET /admin/actions/jobs
# operationId: listAdminWorkflowJobs
export def "admin-actions-jobs listAdminWorkflowJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/actions/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all runners
#
# GET /admin/actions/runners
# operationId: getAdminRunners
export def "admin-actions-runners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool> # filter by disabled status (true or false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disabled" $disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/actions/runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a global actions runner registration token
#
# POST /admin/actions/runners/registration-token
# operationId: adminCreateRunnerRegistrationToken
export def "admin-actions-runners-registration-token adminCreateRunnerRegistrationToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/actions/runners/registration-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a global runner
#
# GET /admin/actions/runners/{runner_id}
# operationId: getAdminRunner
export def "admin-actions-runners get" [
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a global runner
#
# DELETE /admin/actions/runners/{runner_id}
# operationId: deleteAdminRunner
export def "admin-actions-runners delete" [
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a global runner
#
# PATCH /admin/actions/runners/{runner_id}
# operationId: updateAdminRunner
export def "admin-actions-runners updateAdminRunner" [
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/actions/runners/($runner_id)")
  let body = {disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all runs
#
# GET /admin/actions/runs
# operationId: listAdminWorkflowRuns
export def "admin-actions-runs listAdminWorkflowRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: string # workflow event name
  --branch: string # workflow branch
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --actor: string # triggered by user
  --head-sha: string # triggering sha of the workflow run
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "actor" $actor "scalar") (serialize-qp "head_sha" $head_sha "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/actions/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List cron tasks
#
# GET /admin/cron
# operationId: adminCronList
export def "admin-cron adminCronList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/cron" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run cron task
#
# POST /admin/cron/{task}
# operationId: adminCronRun
export def "admin-cron adminCronRun" [
  task: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/cron/($task)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all emails
#
# GET /admin/emails
# operationId: adminGetAllEmails
export def "admin-emails adminGetAllEmails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/emails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search all emails
#
# GET /admin/emails/search
# operationId: adminSearchEmails
export def "admin-emails-search adminSearchEmails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # keyword
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/emails/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List system's webhooks
#
# GET /admin/hooks
# operationId: adminListHooks
export def "admin-hooks adminListHooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --type: string@type-completer # system, default or both kinds of webhooks (default: system)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a hook
#
# POST /admin/hooks
# operationId: adminCreateHook
export def "admin-hooks adminCreateHook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list # List of events that will trigger this webhook
  --name: string # Optional human-readable name for the webhook
  type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/hooks")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a hook
#
# GET /admin/hooks/{id}
# operationId: adminGetHook
export def "admin-hooks adminGetHook" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a hook
#
# DELETE /admin/hooks/{id}
# operationId: adminDeleteHook
export def "admin-hooks adminDeleteHook" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a hook
#
# PATCH /admin/hooks/{id}
# operationId: adminEditHook
export def "admin-hooks adminEditHook" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # Whether the webhook is active and will be triggered
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  --config: record # Configuration settings for the webhook
  --events: list # List of events that trigger this webhook
  --name: string # Optional human-readable name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/hooks/($id)")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all organizations
#
# GET /admin/orgs
# operationId: adminGetAllOrgs
export def "admin-orgs adminGetAllOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/orgs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List unadopted repositories
#
# GET /admin/unadopted
# operationId: adminUnadoptedList
export def "admin-unadopted adminUnadoptedList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --pattern: string # pattern of repositories to search for
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pattern" $pattern "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/unadopted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adopt unadopted files as a repository
#
# POST /admin/unadopted/{owner}/{repo}
# operationId: adminAdoptRepository
export def "admin-unadopted adminAdoptRepository" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/unadopted/($owner)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete unadopted files
#
# DELETE /admin/unadopted/{owner}/{repo}
# operationId: adminDeleteUnadoptedRepository
export def "admin-unadopted adminDeleteUnadoptedRepository" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/unadopted/($owner)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search users according filter conditions
#
# GET /admin/users
# operationId: adminSearchUsers
export def "admin-users adminSearchUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-id: int # ID of the user's login source to search for (format: int64)
  --login-name: string # identifier of the user, provided by the external authenticator
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --qp-sort: string # sort users by attribute. Supported values are "name", "created", "updated" and "id". Default is "name"
  --order: string # sort order, either "asc" (ascending) or "desc" (descending). Default is "asc", ignored if "sort" is not specified.
  --q: string # search term (username, full name, email)
  --visibility: string # visibility filter. Supported values are "public", "limited" and "private".
  --is-active: oneof<nothing, bool> # filter active users
  --is-admin: oneof<nothing, bool> # filter admin users
  --is-restricted: oneof<nothing, bool> # filter restricted users
  --is-2fa-enabled: oneof<nothing, bool> # filter 2FA enabled users
  --is-prohibit-login: oneof<nothing, bool> # filter login prohibited users
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_id" $source_id "scalar") (serialize-qp "login_name" $login_name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "is_admin" $is_admin "scalar") (serialize-qp "is_restricted" $is_restricted "scalar") (serialize-qp "is_2fa_enabled" $is_2fa_enabled "scalar") (serialize-qp "is_prohibit_login" $is_prohibit_login "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /admin/users
# operationId: adminCreateUser
export def "admin-users adminCreateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created-at: string # For explicitly setting the user creation timestamp. Useful when users are migrated from other systems. When omitted, the user's creation timestamp will be set to "now". (format: date-time)
  email: string # format: email
  --full-name: string # The full display name of the user
  --login-name: string # identifier of the user, provided by the external authenticator (if configured) (default: empty)
  --must-change-password: oneof<nothing, bool> # Whether the user must change password on first login
  --password: string # The plain text password for the user
  --restricted: oneof<nothing, bool> # Whether the user has restricted access privileges
  --send-notify: oneof<nothing, bool> # Whether to send welcome notification email to the user
  --source-id: int # The authentication source ID to associate with the user (format: int64)
  username: string # username of the user
  --visibility: string # User visibility level: public, limited, or private
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/users")
  let body = {created_at: $created_at, email: $email, full_name: $full_name, login_name: $login_name, must_change_password: $must_change_password, password: $password, restricted: $restricted, send_notify: $send_notify, source_id: $source_id, username: $username, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /admin/users/{username}
# operationId: adminDeleteUser
export def "admin-users adminDeleteUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --purge: oneof<nothing, bool> # purge the user from the system completely
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "purge" $purge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/users/($username)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an existing user
#
# PATCH /admin/users/{username}
# operationId: adminEditUser
export def "admin-users adminEditUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # Whether the user account is active
  --admin: oneof<nothing, bool> # Whether the user has administrator privileges
  --allow-create-organization: oneof<nothing, bool> # Whether the user can create organizations
  --allow-git-hook: oneof<nothing, bool> # Whether the user can use Git hooks
  --allow-import-local: oneof<nothing, bool> # Whether the user can import local repositories
  --description: string # The user's personal description or bio
  --email: string # format: email
  --full-name: string # The full display name of the user
  --location: string # The user's location or address
  login_name: string # identifier of the user, provided by the external authenticator (if configured) (default: empty)
  --max-repo-creation: int # Maximum number of repositories the user can create (format: int64)
  --must-change-password: oneof<nothing, bool> # Whether the user must change password on next login
  --password: string # The plain text password for the user
  --prohibit-login: oneof<nothing, bool> # Whether the user is prohibited from logging in
  --restricted: oneof<nothing, bool> # Whether the user has restricted access privileges
  source_id: int # format: int64
  --visibility: string # User visibility level: public, limited, or private
  --website: string # The user's personal website URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)")
  let body = {active: $active, admin: $admin, allow_create_organization: $allow_create_organization, allow_git_hook: $allow_git_hook, allow_import_local: $allow_import_local, description: $description, email: $email, full_name: $full_name, location: $location, login_name: $login_name, max_repo_creation: $max_repo_creation, must_change_password: $must_change_password, password: $password, prohibit_login: $prohibit_login, restricted: $restricted, source_id: $source_id, visibility: $visibility, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a user's badges
#
# GET /admin/users/{username}/badges
# operationId: adminListUserBadges
export def "admin-users-badges adminListUserBadges" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/badges")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a badge to a user
#
# POST /admin/users/{username}/badges
# operationId: adminAddUserBadges
export def "admin-users-badges adminAddUserBadges" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --badge-slugs: list # e.g. [badge1, badge2]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/badges")
  let body = {badge_slugs: $badge_slugs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a badge from a user
#
# DELETE /admin/users/{username}/badges
# operationId: adminDeleteUserBadges
export def "admin-users-badges adminDeleteUserBadges" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --badge-slugs: list # e.g. [badge1, badge2]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/badges")
  let body = {badge_slugs: $badge_slugs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a public key on behalf of a user
#
# POST /admin/users/{username}/keys
# operationId: adminCreatePublicKey
export def "admin-users-keys adminCreatePublicKey" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/keys")
  let body = {key: $key, read_only: $read_only, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user's public key
#
# DELETE /admin/users/{username}/keys/{id}
# operationId: adminDeleteUserPublicKey
export def "admin-users-keys adminDeleteUserPublicKey" [
  username: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /admin/users/{username}/orgs
# operationId: adminCreateOrg
export def "admin-users-orgs adminCreateOrg" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The description of the organization
  --email: string # The email address of the organization
  --full-name: string # The full display name of the organization
  --location: string # The location of the organization
  --repo-admin-change-team-access: oneof<nothing, bool> # Whether repository administrators can change team access
  --body-username: string # username of the organization
  --visibility: string@visibility-completer # possible values are `public` (default), `limited` or `private`
  --website: string # The website URL of the organization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/orgs")
  let body = {description: $description, email: $email, full_name: $full_name, location: $location, repo_admin_change_team_access: $repo_admin_change_team_access, username: $body_username, visibility: $visibility, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename a user
#
# POST /admin/users/{username}/rename
# operationId: adminRenameUser
export def "admin-users-rename adminRenameUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_username: string # New username for this user. This name cannot be in use yet by any other user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/rename")
  let body = {new_username: $new_username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a repository on behalf of a user
#
# POST /admin/users/{username}/repos
# operationId: adminCreateRepo
export def "admin-users-repos adminCreateRepo" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --object-format-name: string@object-format-name-completer # ObjectFormatName of the underlying git repository, empty string for default (sha1)
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($username)/repos")
  let body = {auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, object_format_name: $object_format_name, private: $private, readme: $readme, template: $template, trust_model: $trust_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a list of all gitignore templates
#
# GET /gitignore/templates
# operationId: listGitignoresTemplates
export def "gitignore-templates listGitignoresTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gitignore/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about a gitignore template
#
# GET /gitignore/templates/{name}
# operationId: getGitignoreTemplateInfo
export def "gitignore-templates get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/gitignore/templates/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all label templates
#
# GET /label/templates
# operationId: listLabelTemplates
export def "label-templates listLabelTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/label/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all labels in a template
#
# GET /label/templates/{name}
# operationId: getLabelTemplateInfo
export def "label-templates get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/label/templates/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of all license templates
#
# GET /licenses
# operationId: listLicenseTemplates
export def "licenses listLicenseTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licenses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns information about a license template
#
# GET /licenses/{name}
# operationId: getLicenseTemplateInfo
export def "licenses get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/licenses/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Render a markdown document as HTML
#
# POST /markdown
# operationId: renderMarkdown
export def "markdown renderMarkdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Context: string # URL path for rendering issue, media and file links Expected format: /subpath/{user}/{repo}/src/{branch, commit, tag}/{identifier/path}/{file/dir}  in: body
  --Mode: string # Mode to render (markdown, comment, wiki, file)  in: body
  --Text: string # Text markdown to render  in: body
  --Wiki: oneof<nothing, bool> # Is it a wiki page? (use mode=wiki instead)  Deprecated: true in: body
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markdown")
  let body = {Context: $Context, Mode: $Mode, Text: $Text, Wiki: $Wiki} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Render raw markdown as HTML
#
# POST /markdown/raw
# operationId: renderMarkdownRaw
export def "markdown-raw renderMarkdownRaw" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markdown/raw")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Render a markup document as HTML
#
# POST /markup
# operationId: renderMarkup
export def "markup renderMarkup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Context: string # URL path for rendering issue, media and file links Expected format: /subpath/{user}/{repo}/src/{branch, commit, tag}/{identifier/path}/{file/dir}  in: body
  --FilePath: string # File path for detecting extension in file mode  in: body
  --Mode: string # Mode to render (markdown, comment, wiki, file)  in: body
  --Text: string # Text markup to render  in: body
  --Wiki: oneof<nothing, bool> # Is it a wiki page? (use mode=wiki instead)  Deprecated: true in: body
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markup")
  let body = {Context: $Context, FilePath: $FilePath, Mode: $Mode, Text: $Text, Wiki: $Wiki} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users's notification threads
#
# GET /notifications
# operationId: notifyGetList
export def "notifications notifyGetList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # If true, show notifications marked as read. Default value is false
  --status-types: list # Show notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread & pinned.
  --subject-type: list # filter notifications by subject type
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "subject-type" $subject_type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark notification threads as read, pinned or unread
#
# PUT /notifications
# operationId: notifyReadList
export def "notifications notifyReadList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --last-read-at: string # Describes the last point that notifications were checked. Anything updated since this time will not be updated. (format: date-time)
  --all: string # If true, mark all notifications on this repo. Default value is false
  --status-types: list # Mark notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread.
  --to-status: string # Status to mark notifications as, Defaults to read.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_read_at" $last_read_at "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "to-status" $to_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if unread notifications exist
#
# GET /notifications/new
# operationId: notifyNewAvailable
export def "notifications-new notifyNewAvailable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/new")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get notification thread by ID
#
# GET /notifications/threads/{id}
# operationId: notifyGetThread
export def "notifications-threads notifyGetThread" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/threads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark notification thread as read by ID
#
# PATCH /notifications/threads/{id}
# operationId: notifyReadThread
export def "notifications-threads notifyReadThread" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --to-status: string # Status to mark notifications as (default: read)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "to-status" $to_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/threads/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a repository in an organization
#
# POST /org/{org}/repos
# DEPRECATED
# operationId: createOrgRepoDeprecated
@deprecated
export def "org-repos createOrgRepoDeprecated" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --object-format-name: string@object-format-name-completer # ObjectFormatName of the underlying git repository, empty string for default (sha1)
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/($org)/repos")
  let body = {auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, object_format_name: $object_format_name, private: $private, readme: $readme, template: $template, trust_model: $trust_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get list of organizations
#
# GET /orgs
# operationId: orgGetAll
export def "orgs orgGetAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /orgs
# operationId: orgCreate
export def "orgs orgCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The description of the organization
  --email: string # The email address of the organization
  --full-name: string # The full display name of the organization
  --location: string # The location of the organization
  --repo-admin-change-team-access: oneof<nothing, bool> # Whether repository administrators can change team access
  username: string # username of the organization
  --visibility: string@visibility-completer # possible values are `public` (default), `limited` or `private`
  --website: string # The website URL of the organization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgs")
  let body = {description: $description, email: $email, full_name: $full_name, location: $location, repo_admin_change_team_access: $repo_admin_change_team_access, username: $username, visibility: $visibility, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an organization
#
# GET /orgs/{org}
# operationId: orgGet
export def "orgs orgGet" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization
#
# DELETE /orgs/{org}
# operationId: orgDelete
export def "orgs orgDelete" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an organization
#
# PATCH /orgs/{org}
# operationId: orgEdit
export def "orgs orgEdit" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # The description of the organization
  --email: string # The email address of the organization; use empty string to clear
  --full-name: string # The full display name of the organization
  --location: string # The location of the organization
  --repo-admin-change-team-access: oneof<nothing, bool> # Whether repository administrators can change team access
  --visibility: string@visibility-completer # possible values are `public`, `limited` or `private`
  --website: string # The website URL of the organization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)")
  let body = {description: $description, email: $email, full_name: $full_name, location: $location, repo_admin_change_team_access: $repo_admin_change_team_access, visibility: $visibility, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get org-level workflow jobs
#
# GET /orgs/{org}/actions/jobs
# operationId: getOrgWorkflowJobs
export def "orgs-actions-jobs get" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/actions/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get org-level runners
#
# GET /orgs/{org}/actions/runners
# operationId: getOrgRunners
export def "orgs-actions-runners list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool> # filter by disabled status (true or false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disabled" $disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/actions/runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an organization's actions runner registration token
#
# POST /orgs/{org}/actions/runners/registration-token
# operationId: orgCreateRunnerRegistrationToken
export def "orgs-actions-runners-registration-token orgCreateRunnerRegistrationToken" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/runners/registration-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an org-level runner
#
# GET /orgs/{org}/actions/runners/{runner_id}
# operationId: getOrgRunner
export def "orgs-actions-runners get" [
  org: string
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an org-level runner
#
# DELETE /orgs/{org}/actions/runners/{runner_id}
# operationId: deleteOrgRunner
export def "orgs-actions-runners delete" [
  org: string
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an org-level runner
#
# PATCH /orgs/{org}/actions/runners/{runner_id}
# operationId: updateOrgRunner
export def "orgs-actions-runners updateOrgRunner" [
  org: string
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/runners/($runner_id)")
  let body = {disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get org-level workflow runs
#
# GET /orgs/{org}/actions/runs
# operationId: getOrgWorkflowRuns
export def "orgs-actions-runs get" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: string # workflow event name
  --branch: string # workflow branch
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --actor: string # triggered by user
  --head-sha: string # triggering sha of the workflow run
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "actor" $actor "scalar") (serialize-qp "head_sha" $head_sha "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/actions/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an organization's actions secrets
#
# GET /orgs/{org}/actions/secrets
# operationId: orgListActionsSecrets
export def "orgs-actions-secrets orgListActionsSecrets" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/actions/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update a secret value in an organization
#
# PUT /orgs/{org}/actions/secrets/{secretname}
# operationId: updateOrgSecret
export def "orgs-actions-secrets updateOrgSecret" [
  org: string
  secretname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: string # Data of the secret to update
  --description: string # Description of the secret to update
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/secrets/($secretname)")
  let body = {data: $data, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a secret in an organization
#
# DELETE /orgs/{org}/actions/secrets/{secretname}
# operationId: deleteOrgSecret
export def "orgs-actions-secrets delete" [
  org: string
  secretname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/secrets/($secretname)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an org-level variables list
#
# GET /orgs/{org}/actions/variables
# operationId: getOrgVariablesList
export def "orgs-actions-variables list" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/actions/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an org-level variable
#
# GET /orgs/{org}/actions/variables/{variablename}
# operationId: getOrgVariable
export def "orgs-actions-variables get" [
  org: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/variables/($variablename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an org-level variable
#
# PUT /orgs/{org}/actions/variables/{variablename}
# operationId: updateOrgVariable
export def "orgs-actions-variables updateOrgVariable" [
  org: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the variable to update
  --name: string # New name for the variable. If the field is empty, the variable name won't be updated.
  value: string # Value of the variable to update
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/variables/($variablename)")
  let body = {description: $description, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an org-level variable
#
# POST /orgs/{org}/actions/variables/{variablename}
# operationId: createOrgVariable
export def "orgs-actions-variables createOrgVariable" [
  org: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the variable to create
  value: string # Value of the variable to create
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/variables/($variablename)")
  let body = {description: $description, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an org-level variable
#
# DELETE /orgs/{org}/actions/variables/{variablename}
# operationId: deleteOrgVariable
export def "orgs-actions-variables delete" [
  org: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/actions/variables/($variablename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an organization's activity feeds
#
# GET /orgs/{org}/activities/feeds
# operationId: orgListActivityFeeds
export def "orgs-activities-feeds orgListActivityFeeds" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # the date of the activities to be found (format: date)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/activities/feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Avatar
#
# POST /orgs/{org}/avatar
# operationId: orgUpdateAvatar
export def "orgs-avatar orgUpdateAvatar" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --image: string # image must be base64 encoded
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/avatar")
  let body = {image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Avatar
#
# DELETE /orgs/{org}/avatar
# operationId: orgDeleteAvatar
export def "orgs-avatar orgDeleteAvatar" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users blocked by the organization
#
# GET /orgs/{org}/blocks
# operationId: organizationListBlocks
export def "orgs-blocks organizationListBlocks" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a user is blocked by the organization
#
# GET /orgs/{org}/blocks/{username}
# operationId: organizationCheckUserBlock
export def "orgs-blocks organizationCheckUserBlock" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/blocks/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Block a user
#
# PUT /orgs/{org}/blocks/{username}
# operationId: organizationBlockUser
export def "orgs-blocks organizationBlockUser" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # optional note for the block
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "note" $note "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/blocks/($username)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unblock a user
#
# DELETE /orgs/{org}/blocks/{username}
# operationId: organizationUnblockUser
export def "orgs-blocks organizationUnblockUser" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/blocks/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an organization's webhooks
#
# GET /orgs/{org}/hooks
# operationId: orgListHooks
export def "orgs-hooks orgListHooks" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a hook
#
# POST /orgs/{org}/hooks
# operationId: orgCreateHook
export def "orgs-hooks orgCreateHook" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list # List of events that will trigger this webhook
  --name: string # Optional human-readable name for the webhook
  type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/hooks")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a hook
#
# GET /orgs/{org}/hooks/{id}
# operationId: orgGetHook
export def "orgs-hooks orgGetHook" [
  org: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a hook
#
# DELETE /orgs/{org}/hooks/{id}
# operationId: orgDeleteHook
export def "orgs-hooks orgDeleteHook" [
  org: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a hook
#
# PATCH /orgs/{org}/hooks/{id}
# operationId: orgEditHook
export def "orgs-hooks orgEditHook" [
  org: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # Whether the webhook is active and will be triggered
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  --config: record # Configuration settings for the webhook
  --events: list # List of events that trigger this webhook
  --name: string # Optional human-readable name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/hooks/($id)")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an organization's labels
#
# GET /orgs/{org}/labels
# operationId: orgListLabels
export def "orgs-labels orgListLabels" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a label for an organization
#
# POST /orgs/{org}/labels
# operationId: orgCreateLabel
export def "orgs-labels orgCreateLabel" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  color: string # e.g. #00aabb
  --description: string # Description provides additional context about the label's purpose
  --exclusive: oneof<nothing, bool> # e.g. false
  --is-archived: oneof<nothing, bool> # e.g. false
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/labels")
  let body = {color: $color, description: $description, exclusive: $exclusive, is_archived: $is_archived, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single label
#
# GET /orgs/{org}/labels/{id}
# operationId: orgGetLabel
export def "orgs-labels orgGetLabel" [
  org: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a label
#
# DELETE /orgs/{org}/labels/{id}
# operationId: orgDeleteLabel
export def "orgs-labels orgDeleteLabel" [
  org: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a label
#
# PATCH /orgs/{org}/labels/{id}
# operationId: orgEditLabel
export def "orgs-labels orgEditLabel" [
  org: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # e.g. #00aabb
  --description: string # Description provides additional context about the label's purpose
  --exclusive: oneof<nothing, bool> # e.g. false
  --is-archived: oneof<nothing, bool> # e.g. false
  --name: string # Name is the new display name for the label
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/labels/($id)")
  let body = {color: $color, description: $description, exclusive: $exclusive, is_archived: $is_archived, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an organization's members
#
# GET /orgs/{org}/members
# operationId: orgListMembers
export def "orgs-members orgListMembers" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a user is a member of an organization
#
# GET /orgs/{org}/members/{username}
# operationId: orgIsMember
export def "orgs-members orgIsMember" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a member from an organization
#
# DELETE /orgs/{org}/members/{username}
# operationId: orgDeleteMember
export def "orgs-members orgDeleteMember" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an organization's public members
#
# GET /orgs/{org}/public_members
# operationId: orgListPublicMembers
export def "orgs-public-members orgListPublicMembers" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/public_members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a user is a public member of an organization
#
# GET /orgs/{org}/public_members/{username}
# operationId: orgIsPublicMember
export def "orgs-public-members orgIsPublicMember" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/public_members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publicize a user's membership
#
# PUT /orgs/{org}/public_members/{username}
# operationId: orgPublicizeMember
export def "orgs-public-members orgPublicizeMember" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/public_members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Conceal a user's membership
#
# DELETE /orgs/{org}/public_members/{username}
# operationId: orgConcealMember
export def "orgs-public-members orgConcealMember" [
  org: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/public_members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename an organization
#
# POST /orgs/{org}/rename
# operationId: renameOrg
export def "orgs-rename renameOrg" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_name: string # New username for this org. This name cannot be in use yet by any other user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/rename")
  let body = {new_name: $new_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an organization's repos
#
# GET /orgs/{org}/repos
# operationId: orgListRepos
export def "orgs-repos orgListRepos" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/repos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a repository in an organization
#
# POST /orgs/{org}/repos
# operationId: createOrgRepo
export def "orgs-repos createOrgRepo" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --object-format-name: string@object-format-name-completer # ObjectFormatName of the underlying git repository, empty string for default (sha1)
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/repos")
  let body = {auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, object_format_name: $object_format_name, private: $private, readme: $readme, template: $template, trust_model: $trust_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an organization's teams
#
# GET /orgs/{org}/teams
# operationId: orgListTeams
export def "orgs-teams orgListTeams" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /orgs/{org}/teams
# operationId: orgCreateTeam
export def "orgs-teams orgCreateTeam" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --can-create-org-repo: oneof<nothing, bool> # Whether the team can create repositories in the organization
  --description: string # The description of the team
  --includes-all-repositories: oneof<nothing, bool> # Whether the team has access to all repositories in the organization
  name: string
  --permission: string@permission-completer
  --units: list # e.g. [repo.actions, repo.code, repo.issues, repo.ext_issues, repo.wiki, repo.ext_wiki, repo.pulls, repo.releases, repo.projects, repo.ext_wiki]
  --units-map: record # e.g. {"repo.actions","repo.packages","repo.code":"read","repo.issues":"write","repo.ext_issues":"none","repo.wiki":"admin","repo.pulls":"owner","repo.releases":"none","repo.projects":"none","repo.ext_wiki":"none"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org)/teams")
  let body = {can_create_org_repo: $can_create_org_repo, description: $description, includes_all_repositories: $includes_all_repositories, name: $name, permission: $permission, units: $units, units_map: $units_map} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for teams within an organization
#
# GET /orgs/{org}/teams/search
# operationId: teamSearch
export def "orgs-teams-search teamSearch" [
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # keywords to search
  --include-desc: oneof<nothing, bool> # include search within team description (defaults to true)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> record<data: table<can_create_org_repo: bool, description: string, id: int, includes_all_repositories: bool, name: string, organization: record, permission: string, units: list, units_map: record>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "include_desc" $include_desc "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orgs/($org)/teams/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all packages of an owner
#
# GET /packages/{owner}
# operationId: listPackages
export def "packages listPackages" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --type: string@type-completer-2 # package type filter
  --q: string # name filter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packages/($owner)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all versions of a package
#
# GET /packages/{owner}/{type}/{name}
# operationId: listPackageVersions
export def "packages listPackageVersions" [
  owner: string
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a package
#
# DELETE /packages/{owner}/{type}/{name}
# operationId: deletePackage
export def "packages delete-by-owner-type-name" [
  owner: string
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the latest version of a package
#
# GET /packages/{owner}/{type}/{name}/-/latest
# operationId: getLatestPackageVersion
export def "packages-latest get" [
  owner: string
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)/-/latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link a package to a repository
#
# POST /packages/{owner}/{type}/{name}/-/link/{repo_name}
# operationId: linkPackage
export def "packages-link linkPackage" [
  owner: string
  type: string
  name: string
  repo_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)/-/link/($repo_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlink a package from a repository
#
# POST /packages/{owner}/{type}/{name}/-/unlink
# operationId: unlinkPackage
export def "packages-unlink unlinkPackage" [
  owner: string
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)/-/unlink")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a package
#
# GET /packages/{owner}/{type}/{name}/{version}
# operationId: getPackage
export def "packages get" [
  owner: string
  type: string
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a package version
#
# DELETE /packages/{owner}/{type}/{name}/{version}
# operationId: deletePackageVersion
export def "packages delete-by-owner-type-name-version" [
  owner: string
  type: string
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all files of a package
#
# GET /packages/{owner}/{type}/{name}/{version}/files
# operationId: listPackageFiles
export def "packages-files listPackageFiles" [
  owner: string
  type: string
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/packages/($owner)/($type)/($name)/($version)/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for issues across the repositories that the user has access to
#
# GET /repos/issues/search
# operationId: issueSearchIssues
export def "repos-issues-search issueSearchIssues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # State of the issue (default: open)
  --labels: string # Comma-separated list of label names. Fetch only issues that have any of these labels. Non existent labels are discarded.
  --milestones: string # Comma-separated list of milestone names. Fetch only issues that have any of these milestones. Non existent milestones are discarded.
  --q: string # Search string
  --type: string@type-completer-3 # Filter by issue type
  --since: string # Only show issues updated after the given time (RFC 3339 format) (format: date-time)
  --before: string # Only show issues updated before the given time (RFC 3339 format) (format: date-time)
  --assigned: oneof<nothing, bool> # Filter issues or pulls assigned to the authenticated user (default: false)
  --created: oneof<nothing, bool> # Filter issues or pulls created by the authenticated user (default: false)
  --mentioned: oneof<nothing, bool> # Filter issues or pulls mentioning the authenticated user (default: false)
  --review-requested: oneof<nothing, bool> # Filter pull requests where the authenticated user's review was requested (default: false)
  --reviewed: oneof<nothing, bool> # Filter pull requests reviewed by the authenticated user (default: false)
  --owner: string # Filter by repository owner
  --created-by: string # Only show items which were created by the given user
  --team: string # Filter by team (requires organization owner parameter)
  --page: int # Page number of results to return (1-based) (default: 1)
  --limit: int # Number of items per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "milestones" $milestones "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "assigned" $assigned "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "mentioned" $mentioned "scalar") (serialize-qp "review_requested" $review_requested "scalar") (serialize-qp "reviewed" $reviewed "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repos/issues/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Migrate a remote git repository
#
# POST /repos/migrate
# operationId: repoMigrate
export def "repos-migrate repoMigrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auth-password: string
  --auth-token: string
  --auth-username: string
  --aws-access-key-id: string
  --aws-secret-access-key: string
  clone_addr: string
  --description: string
  --issues: oneof<nothing, bool>
  --labels: oneof<nothing, bool>
  --lfs: oneof<nothing, bool>
  --lfs-endpoint: string
  --milestones: oneof<nothing, bool>
  --mirror: oneof<nothing, bool>
  --mirror-interval: string
  --private: oneof<nothing, bool>
  --pull-requests: oneof<nothing, bool>
  --releases: oneof<nothing, bool>
  repo_name: string
  --repo-owner: string # the organization's name or individual user's name who will own the migrated repository
  --service: string@service-completer
  --uid: int # deprecated (only for backwards compatibility, use repo_owner instead) (format: int64)
  --wiki: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/repos/migrate")
  let body = {auth_password: $auth_password, auth_token: $auth_token, auth_username: $auth_username, aws_access_key_id: $aws_access_key_id, aws_secret_access_key: $aws_secret_access_key, clone_addr: $clone_addr, description: $description, issues: $issues, labels: $labels, lfs: $lfs, lfs_endpoint: $lfs_endpoint, milestones: $milestones, mirror: $mirror, mirror_interval: $mirror_interval, private: $private, pull_requests: $pull_requests, releases: $releases, repo_name: $repo_name, repo_owner: $repo_owner, service: $service, uid: $uid, wiki: $wiki} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for repositories
#
# GET /repos/search
# operationId: repoSearch
export def "repos-search repoSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # keyword
  --topic: oneof<nothing, bool> # Limit search to repositories with keyword as topic
  --includeDesc: oneof<nothing, bool> # include search of keyword within repository description
  --uid: int # search only for repos that the user with the given id owns or contributes to (format: int64)
  --priority-owner-id: int # repo owner to prioritize in the results (format: int64)
  --team-id: int # search only for repos that belong to the given team id (format: int64)
  --starredBy: int # search only for repos that the user with the given id has starred (format: int64)
  --private: oneof<nothing, bool> # include private repositories this user has access to (defaults to true)
  --is-private: oneof<nothing, bool> # show only pubic, private or all repositories (defaults to all)
  --template: oneof<nothing, bool> # include template repositories this user has access to (defaults to true)
  --archived: oneof<nothing, bool> # show only archived, non-archived or all repositories (defaults to all)
  --mode: string # type of repository to search for. Supported values are "fork", "source", "mirror" and "collaborative"
  --exclusive: oneof<nothing, bool> # if `uid` is given, search only for repos that the user owns
  --qp-sort: string # sort repos by attribute. Supported values are "alpha", "created", "updated", "size", "git_size", "lfs_size", "stars", "forks" and "id". Default is "alpha"
  --order: string # sort order, either "asc" (ascending) or "desc" (descending). Default is "asc", ignored if "sort" is not specified.
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "topic" $topic "scalar") (serialize-qp "includeDesc" $includeDesc "scalar") (serialize-qp "uid" $uid "scalar") (serialize-qp "priority_owner_id" $priority_owner_id "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "starredBy" $starredBy "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "is_private" $is_private "scalar") (serialize-qp "template" $template "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "exclusive" $exclusive "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repos/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a repository
#
# GET /repos/{owner}/{repo}
# operationId: repoGet
export def "repos repoGet" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a repository
#
# DELETE /repos/{owner}/{repo}
# operationId: repoDelete
export def "repos repoDelete" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a repository's properties. Only fields that are set will be changed.
#
# PATCH /repos/{owner}/{repo}
# operationId: repoEdit
# --external_tracker shape: {external_tracker_format?: string, external_tracker_regexp_pattern?: string, external_tracker_style?: string, external_tracker_url?: string}
# --external_wiki shape: {external_wiki_url?: string}
# --internal_tracker shape: {allow_only_contributors_to_track_time?: bool, enable_issue_dependencies?: bool, enable_time_tracker?: bool}
export def "repos repoEdit" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-fast-forward-only-merge: oneof<nothing, bool> # either `true` to allow fast-forward-only merging pull requests, or `false` to prevent fast-forward-only merging.
  --allow-manual-merge: oneof<nothing, bool> # either `true` to allow mark pr as merged manually, or `false` to prevent it.
  --allow-merge-commits: oneof<nothing, bool> # either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging pull requests with merge commits.
  --allow-rebase: oneof<nothing, bool> # either `true` to allow rebase-merging pull requests, or `false` to prevent rebase-merging.
  --allow-rebase-explicit: oneof<nothing, bool> # either `true` to allow rebase with explicit merge commits (--no-ff), or `false` to prevent rebase with explicit merge commits.
  --allow-rebase-update: oneof<nothing, bool> # either `true` to allow updating pull request branch by rebase, or `false` to prevent it.
  --allow-squash-merge: oneof<nothing, bool> # either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging.
  --archived: oneof<nothing, bool> # set to `true` to archive this repository.
  --autodetect-manual-merge: oneof<nothing, bool> # either `true` to enable AutodetectManualMerge, or `false` to prevent it. Note: In some special cases, misjudgments can occur.
  --default-allow-maintainer-edit: oneof<nothing, bool> # set to `true` to allow edits from maintainers by default
  --default-branch: string # sets the default branch for this repository.
  --default-delete-branch-after-merge: oneof<nothing, bool> # set to `true` to delete pr branch after merge by default
  --default-merge-style: string # set to a merge style to be used by this repository: "merge", "rebase", "rebase-merge", "squash", or "fast-forward-only".
  --description: string # a short description of the repository.
  --enable-prune: oneof<nothing, bool> # enable prune - remove obsolete remote-tracking references when mirroring
  --external-tracker: record # ExternalTracker represents settings for external tracker — shape: {external_tracker_format?: string, external_tracker_regexp_pattern?: string, external_tracker_style?: string, external_tracker_url?: string}
  --external-wiki: record # ExternalWiki represents setting for external wiki — shape: {external_wiki_url?: string}
  --has-actions: oneof<nothing, bool> # either `true` to enable actions unit, or `false` to disable them.
  --has-code: oneof<nothing, bool> # either `true` to enable code for this repository or `false` to disable it.
  --has-issues: oneof<nothing, bool> # either `true` to enable issues for this repository or `false` to disable them.
  --has-packages: oneof<nothing, bool> # either `true` to enable packages unit, or `false` to disable them.
  --has-projects: oneof<nothing, bool> # either `true` to enable project unit, or `false` to disable them.
  --has-pull-requests: oneof<nothing, bool> # either `true` to allow pull requests, or `false` to prevent pull request.
  --has-releases: oneof<nothing, bool> # either `true` to enable releases unit, or `false` to disable them.
  --has-wiki: oneof<nothing, bool> # either `true` to enable the wiki for this repository or `false` to disable it.
  --ignore-whitespace-conflicts: oneof<nothing, bool> # either `true` to ignore whitespace for conflicts, or `false` to not ignore whitespace.
  --internal-tracker: record # InternalTracker represents settings for internal tracker — shape: {allow_only_contributors_to_track_time?: bool, enable_issue_dependencies?: bool, enable_time_tracker?: bool}
  --mirror-interval: string # set to a string like `8h30m0s` to set the mirror interval time
  --name: string # name of the repository
  --private: oneof<nothing, bool> # either `true` to make the repository private or `false` to make it public. Note: you will get a 422 error if the organization restricts changing repository visibility to organization owners and a non-owner tries to change the value of private.
  --projects-mode: string # `repo` to only allow repo-level projects, `owner` to only allow owner projects, `all` to allow both.
  --template: oneof<nothing, bool> # either `true` to make this repository a template or `false` to make it a normal repository
  --website: string # a URL with more information about the repository.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)")
  let body = {allow_fast_forward_only_merge: $allow_fast_forward_only_merge, allow_manual_merge: $allow_manual_merge, allow_merge_commits: $allow_merge_commits, allow_rebase: $allow_rebase, allow_rebase_explicit: $allow_rebase_explicit, allow_rebase_update: $allow_rebase_update, allow_squash_merge: $allow_squash_merge, archived: $archived, autodetect_manual_merge: $autodetect_manual_merge, default_allow_maintainer_edit: $default_allow_maintainer_edit, default_branch: $default_branch, default_delete_branch_after_merge: $default_delete_branch_after_merge, default_merge_style: $default_merge_style, description: $description, enable_prune: $enable_prune, external_tracker: $external_tracker, external_wiki: $external_wiki, has_actions: $has_actions, has_code: $has_code, has_issues: $has_issues, has_packages: $has_packages, has_projects: $has_projects, has_pull_requests: $has_pull_requests, has_releases: $has_releases, has_wiki: $has_wiki, ignore_whitespace_conflicts: $ignore_whitespace_conflicts, internal_tracker: $internal_tracker, mirror_interval: $mirror_interval, name: $name, private: $private, projects_mode: $projects_mode, template: $template, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all artifacts for a repository
#
# GET /repos/{owner}/{repo}/actions/artifacts
# operationId: getArtifacts
export def "repos-actions-artifacts list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the artifact
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/artifacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a specific artifact for a workflow run
#
# GET /repos/{owner}/{repo}/actions/artifacts/{artifact_id}
# operationId: getArtifact
export def "repos-actions-artifacts get" [
  owner: string
  repo: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/artifacts/($artifact_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a specific artifact for a workflow run
#
# DELETE /repos/{owner}/{repo}/actions/artifacts/{artifact_id}
# operationId: deleteArtifact
export def "repos-actions-artifacts delete" [
  owner: string
  repo: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/artifacts/($artifact_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Downloads a specific artifact for a workflow run redirects to blob url
#
# GET /repos/{owner}/{repo}/actions/artifacts/{artifact_id}/zip
# operationId: downloadArtifact
export def "repos-actions-artifacts-zip downloadArtifact" [
  owner: string
  repo: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/artifacts/($artifact_id)/zip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all jobs for a repository
#
# GET /repos/{owner}/{repo}/actions/jobs
# operationId: listWorkflowJobs
export def "repos-actions-jobs listWorkflowJobs" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a specific workflow job for a workflow run
#
# GET /repos/{owner}/{repo}/actions/jobs/{job_id}
# operationId: getWorkflowJob
export def "repos-actions-jobs get" [
  owner: string
  repo: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/jobs/($job_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Downloads the job logs for a workflow run
#
# GET /repos/{owner}/{repo}/actions/jobs/{job_id}/logs
# operationId: downloadActionsRunJobLogs
export def "repos-actions-jobs-logs downloadActionsRunJobLogs" [
  owner: string
  repo: string
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/jobs/($job_id)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get repo-level runners
#
# GET /repos/{owner}/{repo}/actions/runners
# operationId: getRepoRunners
export def "repos-actions-runners list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool> # filter by disabled status (true or false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disabled" $disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a repository's actions runner registration token
#
# POST /repos/{owner}/{repo}/actions/runners/registration-token
# operationId: repoCreateRunnerRegistrationToken
export def "repos-actions-runners-registration-token repoCreateRunnerRegistrationToken" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runners/registration-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a repo-level runner
#
# GET /repos/{owner}/{repo}/actions/runners/{runner_id}
# operationId: getRepoRunner
export def "repos-actions-runners get" [
  owner: string
  repo: string
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a repo-level runner
#
# DELETE /repos/{owner}/{repo}/actions/runners/{runner_id}
# operationId: deleteRepoRunner
export def "repos-actions-runners delete" [
  owner: string
  repo: string
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a repo-level runner
#
# PATCH /repos/{owner}/{repo}/actions/runners/{runner_id}
# operationId: updateRepoRunner
export def "repos-actions-runners updateRepoRunner" [
  owner: string
  repo: string
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runners/($runner_id)")
  let body = {disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all runs for a repository run
#
# GET /repos/{owner}/{repo}/actions/runs
# operationId: getWorkflowRuns
export def "repos-actions-runs get" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: string # workflow event name
  --branch: string # workflow branch
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --actor: string # triggered by user
  --head-sha: string # triggering sha of the workflow run
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "actor" $actor "scalar") (serialize-qp "head_sha" $head_sha "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a specific workflow run
#
# GET /repos/{owner}/{repo}/actions/runs/{run}
# operationId: GetWorkflowRun
export def "repos-actions-runs GetWorkflowRun" [
  owner: string
  repo: string
  run: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs/($run)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a workflow run
#
# DELETE /repos/{owner}/{repo}/actions/runs/{run}
# operationId: deleteActionRun
export def "repos-actions-runs delete" [
  owner: string
  repo: string
  run: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs/($run)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all artifacts for a repository run
#
# GET /repos/{owner}/{repo}/actions/runs/{run}/artifacts
# operationId: getArtifactsOfRun
export def "repos-actions-runs-artifacts get" [
  owner: string
  repo: string
  run: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the artifact
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs/($run)/artifacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all jobs for a workflow run
#
# GET /repos/{owner}/{repo}/actions/runs/{run}/jobs
# operationId: listWorkflowRunJobs
export def "repos-actions-runs-jobs listWorkflowRunJobs" [
  owner: string
  repo: string
  run: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs/($run)/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reruns a specific workflow job in a run
#
# POST /repos/{owner}/{repo}/actions/runs/{run}/jobs/{job_id}/rerun
# operationId: rerunWorkflowJob
export def "repos-actions-runs-jobs-rerun rerunWorkflowJob" [
  owner: string
  repo: string
  run: int
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs/($run)/jobs/($job_id)/rerun")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reruns an entire workflow run
#
# POST /repos/{owner}/{repo}/actions/runs/{run}/rerun
# operationId: rerunWorkflowRun
export def "repos-actions-runs-rerun rerunWorkflowRun" [
  owner: string
  repo: string
  run: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs/($run)/rerun")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reruns all failed jobs in a workflow run
#
# POST /repos/{owner}/{repo}/actions/runs/{run}/rerun-failed-jobs
# operationId: rerunFailedWorkflowRun
export def "repos-actions-runs-rerun-failed-jobs rerunFailedWorkflowRun" [
  owner: string
  repo: string
  run: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/runs/($run)/rerun-failed-jobs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an repo's actions secrets
#
# GET /repos/{owner}/{repo}/actions/secrets
# operationId: repoListActionsSecrets
export def "repos-actions-secrets repoListActionsSecrets" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update a secret value in a repository
#
# PUT /repos/{owner}/{repo}/actions/secrets/{secretname}
# operationId: updateRepoSecret
export def "repos-actions-secrets updateRepoSecret" [
  owner: string
  repo: string
  secretname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: string # Data of the secret to update
  --description: string # Description of the secret to update
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/secrets/($secretname)")
  let body = {data: $data, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a secret in a repository
#
# DELETE /repos/{owner}/{repo}/actions/secrets/{secretname}
# operationId: deleteRepoSecret
export def "repos-actions-secrets delete" [
  owner: string
  repo: string
  secretname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/secrets/($secretname)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repository's action tasks
#
# GET /repos/{owner}/{repo}/actions/tasks
# operationId: ListActionTasks
export def "repos-actions-tasks ListActionTasks" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results, default maximum page size is 50
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get repo-level variables list
#
# GET /repos/{owner}/{repo}/actions/variables
# operationId: getRepoVariablesList
export def "repos-actions-variables list" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a repo-level variable
#
# GET /repos/{owner}/{repo}/actions/variables/{variablename}
# operationId: getRepoVariable
export def "repos-actions-variables get" [
  owner: string
  repo: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/variables/($variablename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a repo-level variable
#
# PUT /repos/{owner}/{repo}/actions/variables/{variablename}
# operationId: updateRepoVariable
export def "repos-actions-variables updateRepoVariable" [
  owner: string
  repo: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the variable to update
  --name: string # New name for the variable. If the field is empty, the variable name won't be updated.
  value: string # Value of the variable to update
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/variables/($variablename)")
  let body = {description: $description, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a repo-level variable
#
# POST /repos/{owner}/{repo}/actions/variables/{variablename}
# operationId: createRepoVariable
export def "repos-actions-variables createRepoVariable" [
  owner: string
  repo: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the variable to create
  value: string # Value of the variable to create
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/variables/($variablename)")
  let body = {description: $description, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a repo-level variable
#
# DELETE /repos/{owner}/{repo}/actions/variables/{variablename}
# operationId: deleteRepoVariable
export def "repos-actions-variables delete" [
  owner: string
  repo: string
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/variables/($variablename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repository workflows
#
# GET /repos/{owner}/{repo}/actions/workflows
# operationId: ActionsListRepositoryWorkflows
export def "repos-actions-workflows ActionsListRepositoryWorkflows" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/workflows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a workflow
#
# GET /repos/{owner}/{repo}/actions/workflows/{workflow_id}
# operationId: ActionsGetWorkflow
export def "repos-actions-workflows ActionsGetWorkflow" [
  owner: string
  repo: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/workflows/($workflow_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable a workflow
#
# PUT /repos/{owner}/{repo}/actions/workflows/{workflow_id}/disable
# operationId: ActionsDisableWorkflow
export def "repos-actions-workflows-disable ActionsDisableWorkflow" [
  owner: string
  repo: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/workflows/($workflow_id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workflow dispatch event
#
# POST /repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches
# operationId: ActionsDispatchWorkflow
export def "repos-actions-workflows-dispatches ActionsDispatchWorkflow" [
  owner: string
  repo: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-run-details: oneof<nothing, bool> # Whether the response should include the workflow run ID and URLs.
  --inputs: record
  ref: string # e.g. refs/heads/main
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_run_details" $return_run_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/workflows/($workflow_id)/dispatches" $qp)
  let body = {inputs: $inputs, ref: $ref} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable a workflow
#
# PUT /repos/{owner}/{repo}/actions/workflows/{workflow_id}/enable
# operationId: ActionsEnableWorkflow
export def "repos-actions-workflows-enable ActionsEnableWorkflow" [
  owner: string
  repo: string
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/actions/workflows/($workflow_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repository's activity feeds
#
# GET /repos/{owner}/{repo}/activities/feeds
# operationId: repoListActivityFeeds
export def "repos-activities-feeds repoListActivityFeeds" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # the date of the activities to be found (format: date)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/activities/feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an archive of a repository
#
# GET /repos/{owner}/{repo}/archive/{archive}
# operationId: repoGetArchive
export def "repos-archive repoGetArchive" [
  owner: string
  repo: string
  archive: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: list # subpath of the repository to download
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/archive/($archive)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return all users that have write access and can be assigned to issues
#
# GET /repos/{owner}/{repo}/assignees
# operationId: repoGetAssignees
export def "repos-assignees repoGetAssignees" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/assignees")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update avatar
#
# POST /repos/{owner}/{repo}/avatar
# operationId: repoUpdateAvatar
export def "repos-avatar repoUpdateAvatar" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --image: string # image must be base64 encoded
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/avatar")
  let body = {image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete avatar
#
# DELETE /repos/{owner}/{repo}/avatar
# operationId: repoDeleteAvatar
export def "repos-avatar repoDeleteAvatar" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List branch protections for a repository
#
# GET /repos/{owner}/{repo}/branch_protections
# operationId: repoListBranchProtection
export def "repos-branch-protections repoListBranchProtection" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branch_protections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a branch protections for a repository
#
# POST /repos/{owner}/{repo}/branch_protections
# operationId: repoCreateBranchProtection
export def "repos-branch-protections repoCreateBranchProtection" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approvals-whitelist-teams: list
  --approvals-whitelist-username: list
  --block-admin-merge-override: oneof<nothing, bool>
  --block-on-official-review-requests: oneof<nothing, bool>
  --block-on-outdated-branch: oneof<nothing, bool>
  --block-on-rejected-reviews: oneof<nothing, bool>
  --branch-name: string # Deprecated: true
  --dismiss-stale-approvals: oneof<nothing, bool>
  --enable-approvals-whitelist: oneof<nothing, bool>
  --enable-force-push: oneof<nothing, bool>
  --enable-force-push-allowlist: oneof<nothing, bool>
  --enable-merge-whitelist: oneof<nothing, bool>
  --enable-push: oneof<nothing, bool>
  --enable-push-whitelist: oneof<nothing, bool>
  --enable-status-check: oneof<nothing, bool>
  --force-push-allowlist-deploy-keys: oneof<nothing, bool>
  --force-push-allowlist-teams: list
  --force-push-allowlist-usernames: list
  --ignore-stale-approvals: oneof<nothing, bool>
  --merge-whitelist-teams: list
  --merge-whitelist-usernames: list
  --priority: int # format: int64
  --protected-file-patterns: string
  --push-whitelist-deploy-keys: oneof<nothing, bool>
  --push-whitelist-teams: list
  --push-whitelist-usernames: list
  --require-signed-commits: oneof<nothing, bool>
  --required-approvals: int # format: int64
  --rule-name: string
  --status-check-contexts: list
  --unprotected-file-patterns: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branch_protections")
  let body = {approvals_whitelist_teams: $approvals_whitelist_teams, approvals_whitelist_username: $approvals_whitelist_username, block_admin_merge_override: $block_admin_merge_override, block_on_official_review_requests: $block_on_official_review_requests, block_on_outdated_branch: $block_on_outdated_branch, block_on_rejected_reviews: $block_on_rejected_reviews, branch_name: $branch_name, dismiss_stale_approvals: $dismiss_stale_approvals, enable_approvals_whitelist: $enable_approvals_whitelist, enable_force_push: $enable_force_push, enable_force_push_allowlist: $enable_force_push_allowlist, enable_merge_whitelist: $enable_merge_whitelist, enable_push: $enable_push, enable_push_whitelist: $enable_push_whitelist, enable_status_check: $enable_status_check, force_push_allowlist_deploy_keys: $force_push_allowlist_deploy_keys, force_push_allowlist_teams: $force_push_allowlist_teams, force_push_allowlist_usernames: $force_push_allowlist_usernames, ignore_stale_approvals: $ignore_stale_approvals, merge_whitelist_teams: $merge_whitelist_teams, merge_whitelist_usernames: $merge_whitelist_usernames, priority: $priority, protected_file_patterns: $protected_file_patterns, push_whitelist_deploy_keys: $push_whitelist_deploy_keys, push_whitelist_teams: $push_whitelist_teams, push_whitelist_usernames: $push_whitelist_usernames, require_signed_commits: $require_signed_commits, required_approvals: $required_approvals, rule_name: $rule_name, status_check_contexts: $status_check_contexts, unprotected_file_patterns: $unprotected_file_patterns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the priorities of branch protections for a repository.
#
# POST /repos/{owner}/{repo}/branch_protections/priority
# operationId: repoUpdateBranchProtectionPriories
export def "repos-branch-protections-priority repoUpdateBranchProtectionPriories" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branch_protections/priority")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific branch protection for the repository
#
# GET /repos/{owner}/{repo}/branch_protections/{name}
# operationId: repoGetBranchProtection
export def "repos-branch-protections repoGetBranchProtection" [
  owner: string
  repo: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branch_protections/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific branch protection for the repository
#
# DELETE /repos/{owner}/{repo}/branch_protections/{name}
# operationId: repoDeleteBranchProtection
export def "repos-branch-protections repoDeleteBranchProtection" [
  owner: string
  repo: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branch_protections/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a branch protections for a repository. Only fields that are set will be changed
#
# PATCH /repos/{owner}/{repo}/branch_protections/{name}
# operationId: repoEditBranchProtection
export def "repos-branch-protections repoEditBranchProtection" [
  owner: string
  repo: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --approvals-whitelist-teams: list
  --approvals-whitelist-username: list
  --block-admin-merge-override: oneof<nothing, bool>
  --block-on-official-review-requests: oneof<nothing, bool>
  --block-on-outdated-branch: oneof<nothing, bool>
  --block-on-rejected-reviews: oneof<nothing, bool>
  --dismiss-stale-approvals: oneof<nothing, bool>
  --enable-approvals-whitelist: oneof<nothing, bool>
  --enable-force-push: oneof<nothing, bool>
  --enable-force-push-allowlist: oneof<nothing, bool>
  --enable-merge-whitelist: oneof<nothing, bool>
  --enable-push: oneof<nothing, bool>
  --enable-push-whitelist: oneof<nothing, bool>
  --enable-status-check: oneof<nothing, bool>
  --force-push-allowlist-deploy-keys: oneof<nothing, bool>
  --force-push-allowlist-teams: list
  --force-push-allowlist-usernames: list
  --ignore-stale-approvals: oneof<nothing, bool>
  --merge-whitelist-teams: list
  --merge-whitelist-usernames: list
  --priority: int # format: int64
  --protected-file-patterns: string
  --push-whitelist-deploy-keys: oneof<nothing, bool>
  --push-whitelist-teams: list
  --push-whitelist-usernames: list
  --require-signed-commits: oneof<nothing, bool>
  --required-approvals: int # format: int64
  --status-check-contexts: list
  --unprotected-file-patterns: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branch_protections/($name)")
  let body = {approvals_whitelist_teams: $approvals_whitelist_teams, approvals_whitelist_username: $approvals_whitelist_username, block_admin_merge_override: $block_admin_merge_override, block_on_official_review_requests: $block_on_official_review_requests, block_on_outdated_branch: $block_on_outdated_branch, block_on_rejected_reviews: $block_on_rejected_reviews, dismiss_stale_approvals: $dismiss_stale_approvals, enable_approvals_whitelist: $enable_approvals_whitelist, enable_force_push: $enable_force_push, enable_force_push_allowlist: $enable_force_push_allowlist, enable_merge_whitelist: $enable_merge_whitelist, enable_push: $enable_push, enable_push_whitelist: $enable_push_whitelist, enable_status_check: $enable_status_check, force_push_allowlist_deploy_keys: $force_push_allowlist_deploy_keys, force_push_allowlist_teams: $force_push_allowlist_teams, force_push_allowlist_usernames: $force_push_allowlist_usernames, ignore_stale_approvals: $ignore_stale_approvals, merge_whitelist_teams: $merge_whitelist_teams, merge_whitelist_usernames: $merge_whitelist_usernames, priority: $priority, protected_file_patterns: $protected_file_patterns, push_whitelist_deploy_keys: $push_whitelist_deploy_keys, push_whitelist_teams: $push_whitelist_teams, push_whitelist_usernames: $push_whitelist_usernames, require_signed_commits: $require_signed_commits, required_approvals: $required_approvals, status_check_contexts: $status_check_contexts, unprotected_file_patterns: $unprotected_file_patterns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a repository's branches
#
# GET /repos/{owner}/{repo}/branches
# operationId: repoListBranches
export def "repos-branches repoListBranches" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a branch
#
# POST /repos/{owner}/{repo}/branches
# operationId: repoCreateBranch
export def "repos-branches repoCreateBranch" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_branch_name: string # Name of the branch to create
  --old-branch-name: string # Deprecated: true Name of the old branch to create from
  --old-ref-name: string # Name of the old branch/tag/commit to create from
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branches")
  let body = {new_branch_name: $new_branch_name, old_branch_name: $old_branch_name, old_ref_name: $old_ref_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a specific branch from a repository, including its effective branch protection
#
# GET /repos/{owner}/{repo}/branches/{branch}
# operationId: repoGetBranch
export def "repos-branches repoGetBranch" [
  owner: string
  repo: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branches/($branch)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a branch reference to a new commit
#
# PUT /repos/{owner}/{repo}/branches/{branch}
# operationId: repoUpdateBranch
export def "repos-branches repoUpdateBranch" [
  owner: string
  repo: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Force update even if the change is not a fast-forward
  new_commit_id: string # New commit SHA (or any ref) the branch should point to
  --old-commit-id: string # Expected old commit SHA of the branch; if provided it must match the current tip
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branches/($branch)")
  let body = {force: $force, new_commit_id: $new_commit_id, old_commit_id: $old_commit_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific branch from a repository
#
# DELETE /repos/{owner}/{repo}/branches/{branch}
# operationId: repoDeleteBranch
export def "repos-branches repoDeleteBranch" [
  owner: string
  repo: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branches/($branch)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename a branch
#
# PATCH /repos/{owner}/{repo}/branches/{branch}
# operationId: repoRenameBranch
export def "repos-branches repoRenameBranch" [
  owner: string
  repo: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # New branch name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/branches/($branch)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a repository's collaborators
#
# GET /repos/{owner}/{repo}/collaborators
# operationId: repoListCollaborators
export def "repos-collaborators repoListCollaborators" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/collaborators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a user is a collaborator of a repository
#
# GET /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoCheckCollaborator
export def "repos-collaborators repoCheckCollaborator" [
  owner: string
  repo: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/collaborators/($collaborator)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or Update a collaborator to a repository
#
# PUT /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoAddCollaborator
export def "repos-collaborators repoAddCollaborator" [
  owner: string
  repo: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string@permission-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/collaborators/($collaborator)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a collaborator from a repository
#
# DELETE /repos/{owner}/{repo}/collaborators/{collaborator}
# operationId: repoDeleteCollaborator
export def "repos-collaborators repoDeleteCollaborator" [
  owner: string
  repo: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/collaborators/($collaborator)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get repository permissions for a user
#
# GET /repos/{owner}/{repo}/collaborators/{collaborator}/permission
# operationId: repoGetRepoPermissions
export def "repos-collaborators-permission repoGetRepoPermissions" [
  owner: string
  repo: string
  collaborator: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/collaborators/($collaborator)/permission")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all commits from a repository
#
# GET /repos/{owner}/{repo}/commits
# operationId: repoGetAllCommits
export def "repos-commits repoGetAllCommits" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sha: string # SHA or branch to start listing commits from (usually 'master')
  --path: string # filepath of a file/dir
  --since: string # Only commits after this date will be returned (ISO 8601 format) (format: date-time)
  --until: string # Only commits before this date will be returned (ISO 8601 format) (format: date-time)
  --stat: oneof<nothing, bool> # include diff stats for every commit (disable for speedup, default 'true')
  --verification: oneof<nothing, bool> # include verification for every commit (disable for speedup, default 'true')
  --files: oneof<nothing, bool> # include a list of affected files for every commit (disable for speedup, default 'true')
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results (ignored if used with 'path')
  --qp-not: string # commits that match the given specifier will not be listed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sha" $sha "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "stat" $stat "scalar") (serialize-qp "verification" $verification "scalar") (serialize-qp "files" $files "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "not" $qp_not "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/commits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit's combined status, by branch/tag/commit reference
#
# GET /repos/{owner}/{repo}/commits/{ref}/status
# operationId: repoGetCombinedStatusByRef
export def "repos-commits-status repoGetCombinedStatusByRef" [
  owner: string
  repo: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/commits/($ref)/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit's statuses, by branch/tag/commit reference
#
# GET /repos/{owner}/{repo}/commits/{ref}/statuses
# operationId: repoListStatusesByRef
export def "repos-commits-statuses repoListStatusesByRef" [
  owner: string
  repo: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # type of sort
  --state: string@state-completer-1 # type of state
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/commits/($ref)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the merged pull request of the commit
#
# GET /repos/{owner}/{repo}/commits/{sha}/pull
# operationId: repoGetCommitPullRequest
export def "repos-commits-pull repoGetCommitPullRequest" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/commits/($sha)/pull")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get commit comparison information
#
# GET /repos/{owner}/{repo}/compare/{basehead}
# operationId: repoCompareDiff
export def "repos-compare repoCompareDiff" [
  owner: string
  repo: string
  basehead: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/compare/($basehead)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the metadata of all the entries of the root dir.
#
# GET /repos/{owner}/{repo}/contents
# operationId: repoGetContentsList
export def "repos-contents repoGetContentsList" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag. Default to the repository’s default branch.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/contents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify multiple files in a repository
#
# POST /repos/{owner}/{repo}/contents
# operationId: repoChangeFiles
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
# --files item shape: {content?: string, from_path?: string, operation: "create"|"update"|"upload"|"rename"|"delete", path: string, sha?: string}
export def "repos-contents repoChangeFiles" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) is the base branch for the changes. If not supplied, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  files: list # list of file operations — item shape: {content?: string, from_path?: string, operation: "create"|"update"|"upload"|"rename"|"delete", path: string, sha?: string}
  --force-push: oneof<nothing, bool> # force_push (optional) will do a force-push if the new branch already exists
  --message: string # message (optional) is the commit message of the changes. If not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from base branch for the changes. If not supplied, the changes will be committed to the base branch
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/contents")
  let body = {author: $author, branch: $branch, committer: $committer, dates: $dates, files: $files, force_push: $force_push, message: $message, new_branch: $new_branch, signoff: $signoff} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# The extended "contents" API, to get file metadata and/or content, or list a directory.
#
# GET /repos/{owner}/{repo}/contents-ext/{filepath}
# operationId: repoGetContentsExt
export def "repos-contents-ext repoGetContentsExt" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # the name of the commit/branch/tag, default to the repository’s default branch.
  --includes: string # By default this API's response only contains file's metadata. Use comma-separated "includes" options to retrieve more fields. Option "file_content" will try to retrieve the file content, "lfs_metadata" will try to retrieve LFS metadata, "commit_metadata" will try to retrieve commit metadata, and "commit_message" will try to retrieve commit message.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar") (serialize-qp "includes" $includes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/contents-ext/($filepath)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the metadata and contents (if a file) of an entry in a repository, or a list of entries if a dir.
#
# GET /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoGetContents
export def "repos-contents repoGetContents" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag. Default to the repository’s default branch.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/contents/($filepath)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a file in a repository if SHA is set, or create the file if SHA is not set
#
# PUT /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoUpdateFile
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-contents repoUpdateFile" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) is the base branch for the changes. If not supplied, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --force-push: oneof<nothing, bool> # force_push (optional) will do a force-push if the new branch already exists
  --from-path: string # from_path (optional) is the path of the original file which will be moved/renamed to the path in the URL
  --message: string # message (optional) is the commit message of the changes. If not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from base branch for the changes. If not supplied, the changes will be committed to the base branch
  --sha: string # the blob ID (SHA) for the file that already exists to update, or leave it empty to create a new file
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/contents/($filepath)")
  let body = {author: $author, branch: $branch, committer: $committer, content: $content, dates: $dates, force_push: $force_push, from_path: $from_path, message: $message, new_branch: $new_branch, sha: $sha, signoff: $signoff} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a file in a repository
#
# POST /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoCreateFile
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-contents repoCreateFile" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) is the base branch for the changes. If not supplied, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string # content must be base64 encoded
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --force-push: oneof<nothing, bool> # force_push (optional) will do a force-push if the new branch already exists
  --message: string # message (optional) is the commit message of the changes. If not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from base branch for the changes. If not supplied, the changes will be committed to the base branch
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/contents/($filepath)")
  let body = {author: $author, branch: $branch, committer: $committer, content: $content, dates: $dates, force_push: $force_push, message: $message, new_branch: $new_branch, signoff: $signoff} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a file in a repository
#
# DELETE /repos/{owner}/{repo}/contents/{filepath}
# operationId: repoDeleteFile
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-contents repoDeleteFile" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) is the base branch for the changes. If not supplied, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --force-push: oneof<nothing, bool> # force_push (optional) will do a force-push if the new branch already exists
  --message: string # message (optional) is the commit message of the changes. If not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from base branch for the changes. If not supplied, the changes will be committed to the base branch
  sha: string # the blob ID (SHA) for the file to delete
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/contents/($filepath)")
  let body = {author: $author, branch: $branch, committer: $committer, dates: $dates, force_push: $force_push, message: $message, new_branch: $new_branch, sha: $sha, signoff: $signoff} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Apply diff patch to repository
#
# POST /repos/{owner}/{repo}/diffpatch
# operationId: repoApplyDiffPatch
# --author shape: {email?: string, name?: string}
# --committer shape: {email?: string, name?: string}
# --dates shape: {author?: string, committer?: string}
export def "repos-diffpatch repoApplyDiffPatch" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  --branch: string # branch (optional) is the base branch for the changes. If not supplied, the default branch is used
  --committer: record # Identity for a person's identity like an author or committer — shape: {email?: string, name?: string}
  content: string
  --dates: record # CommitDateOptions store dates for GIT_AUTHOR_DATE and GIT_COMMITTER_DATE — shape: {author?: string, committer?: string}
  --force-push: oneof<nothing, bool> # force_push (optional) will do a force-push if the new branch already exists
  --message: string # message (optional) is the commit message of the changes. If not supplied, a default message will be used
  --new-branch: string # new_branch (optional) will make a new branch from base branch for the changes. If not supplied, the changes will be committed to the base branch
  --signoff: oneof<nothing, bool> # Add a Signed-off-by trailer by the committer at the end of the commit log message.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/diffpatch")
  let body = {author: $author, branch: $branch, committer: $committer, content: $content, dates: $dates, force_push: $force_push, message: $message, new_branch: $new_branch, signoff: $signoff} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the EditorConfig definitions of a file in a repository
#
# GET /repos/{owner}/{repo}/editorconfig/{filepath}
# operationId: repoGetEditorConfig
export def "repos-editorconfig repoGetEditorConfig" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag. Default to the repository’s default branch.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/editorconfig/($filepath)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the metadata and contents of requested files
#
# GET /repos/{owner}/{repo}/file-contents
# operationId: repoGetFileContents
export def "repos-file-contents repoGetFileContents" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag. Default to the repository’s default branch.
  --qp-body: string # The JSON encoded body (see the POST request): {"files": ["filename1", "filename2"]}
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar") (serialize-qp "body" $qp_body "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/file-contents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the metadata and contents of requested files
#
# POST /repos/{owner}/{repo}/file-contents
# operationId: repoGetFileContentsPost
export def "repos-file-contents repoGetFileContentsPost" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag. Default to the repository’s default branch.
  --files: list # Files is the list of file paths to retrieve
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/file-contents" $qp)
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a repository's forks
#
# GET /repos/{owner}/{repo}/forks
# operationId: listForks
export def "repos-forks listForks" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/forks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fork a repository
#
# POST /repos/{owner}/{repo}/forks
# operationId: createFork
export def "repos-forks createFork" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the forked repository
  --organization: string # organization name, if forking into an organization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/forks")
  let body = {name: $name, organization: $organization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the blob of a repository.
#
# GET /repos/{owner}/{repo}/git/blobs/{sha}
# operationId: GetBlob
export def "repos-git-blobs GetBlob" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/blobs/($sha)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single commit from a repository
#
# GET /repos/{owner}/{repo}/git/commits/{sha}
# operationId: repoGetSingleCommit
export def "repos-git-commits repoGetSingleCommit" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stat: oneof<nothing, bool> # include diff stats for every commit (disable for speedup, default 'true')
  --verification: oneof<nothing, bool> # include verification for every commit (disable for speedup, default 'true')
  --files: oneof<nothing, bool> # include a list of affected files for every commit (disable for speedup, default 'true')
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stat" $stat "scalar") (serialize-qp "verification" $verification "scalar") (serialize-qp "files" $files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/commits/($sha)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit's diff or patch
#
# GET /repos/{owner}/{repo}/git/commits/{sha}.{diffType}
# operationId: repoDownloadCommitDiffOrPatch
export def "repos-git-commits repoDownloadCommitDiffOrPatch" [
  owner: string
  repo: string
  sha: string
  diffType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/commits/($sha).($diffType)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a note corresponding to a single commit from a repository
#
# GET /repos/{owner}/{repo}/git/notes/{sha}
# operationId: repoGetNote
export def "repos-git-notes repoGetNote" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --verification: oneof<nothing, bool> # include verification for every commit (disable for speedup, default 'true')
  --files: oneof<nothing, bool> # include a list of affected files for every commit (disable for speedup, default 'true')
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verification" $verification "scalar") (serialize-qp "files" $files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/notes/($sha)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specified ref or filtered repository's refs
#
# GET /repos/{owner}/{repo}/git/refs
# operationId: repoListAllGitRefs
export def "repos-git-refs repoListAllGitRefs" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/refs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specified ref or filtered repository's refs
#
# GET /repos/{owner}/{repo}/git/refs/{ref}
# operationId: repoListGitRefs
export def "repos-git-refs repoListGitRefs" [
  owner: string
  repo: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/refs/($ref)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the tag object of an annotated tag (not lightweight tags)
#
# GET /repos/{owner}/{repo}/git/tags/{sha}
# operationId: GetAnnotatedTag
export def "repos-git-tags GetAnnotatedTag" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/tags/($sha)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the tree of a repository.
#
# GET /repos/{owner}/{repo}/git/trees/{sha}
# operationId: GetTree
export def "repos-git-trees GetTree" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recursive: oneof<nothing, bool> # show all directories and files
  --page: int # page number; the 'truncated' field in the response will be true if there are still more items after this page, false if the last page
  --per-page: int # number of items per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recursive" $recursive "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/git/trees/($sha)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the hooks in a repository
#
# GET /repos/{owner}/{repo}/hooks
# operationId: repoListHooks
export def "repos-hooks repoListHooks" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a hook
#
# POST /repos/{owner}/{repo}/hooks
# operationId: repoCreateHook
export def "repos-hooks repoCreateHook" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list # List of events that will trigger this webhook
  --name: string # Optional human-readable name for the webhook
  type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the Git hooks in a repository
#
# GET /repos/{owner}/{repo}/hooks/git
# operationId: repoListGitHooks
export def "repos-hooks-git repoListGitHooks" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/git")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Git hook
#
# GET /repos/{owner}/{repo}/hooks/git/{id}
# operationId: repoGetGitHook
export def "repos-hooks-git repoGetGitHook" [
  owner: string
  repo: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/git/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Git hook in a repository
#
# DELETE /repos/{owner}/{repo}/hooks/git/{id}
# operationId: repoDeleteGitHook
export def "repos-hooks-git repoDeleteGitHook" [
  owner: string
  repo: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/git/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a Git hook in a repository
#
# PATCH /repos/{owner}/{repo}/hooks/git/{id}
# operationId: repoEditGitHook
export def "repos-hooks-git repoEditGitHook" [
  owner: string
  repo: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # Content is the new script content for the hook
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/git/($id)")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a hook
#
# GET /repos/{owner}/{repo}/hooks/{id}
# operationId: repoGetHook
export def "repos-hooks repoGetHook" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a hook in a repository
#
# DELETE /repos/{owner}/{repo}/hooks/{id}
# operationId: repoDeleteHook
export def "repos-hooks repoDeleteHook" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a hook in a repository
#
# PATCH /repos/{owner}/{repo}/hooks/{id}
# operationId: repoEditHook
export def "repos-hooks repoEditHook" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # Whether the webhook is active and will be triggered
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  --config: record # Configuration settings for the webhook
  --events: list # List of events that trigger this webhook
  --name: string # Optional human-readable name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/($id)")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test a push webhook
#
# POST /repos/{owner}/{repo}/hooks/{id}/tests
# operationId: repoTestHook
export def "repos-hooks-tests repoTestHook" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag, indicates which commit will be loaded to the webhook payload.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/hooks/($id)/tests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the issue config for a repo
#
# GET /repos/{owner}/{repo}/issue_config
# operationId: repoGetIssueConfig
export def "repos-issue-config repoGetIssueConfig" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issue_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the validation information for a issue config
#
# GET /repos/{owner}/{repo}/issue_config/validate
# operationId: repoValidateIssueConfig
export def "repos-issue-config-validate repoValidateIssueConfig" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issue_config/validate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available issue templates for a repository
#
# GET /repos/{owner}/{repo}/issue_templates
# operationId: repoGetIssueTemplates
export def "repos-issue-templates repoGetIssueTemplates" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issue_templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repository's issues
#
# GET /repos/{owner}/{repo}/issues
# operationId: issueListIssues
export def "repos-issues issueListIssues" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # whether issue is open or closed
  --labels: string # comma separated list of label names. Fetch only issues that have any of this label names. Non existent labels are discarded.
  --q: string # search string
  --type: string@type-completer-3 # filter by type (issues / pulls) if set
  --milestones: string # comma separated list of milestone names or ids. It uses names and fall back to ids. Fetch only issues that have any of this milestones. Non existent milestones are discarded
  --since: string # Only show items updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show items updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --created-by: string # Only show items which were created by the given user
  --assigned-by: string # Only show items for which the given user is assigned
  --mentioned-by: string # Only show items in which the given user was mentioned
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "milestones" $milestones "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "created_by" $created_by "scalar") (serialize-qp "assigned_by" $assigned_by "scalar") (serialize-qp "mentioned_by" $mentioned_by "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an issue. If using deadline only the date will be taken into account, and time of day ignored.
#
# POST /repos/{owner}/{repo}/issues
# operationId: issueCreateIssue
export def "repos-issues issueCreateIssue" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assignee: string # deprecated
  --assignees: list
  --body-body: string
  --closed: oneof<nothing, bool>
  --due-date: string # format: date-time
  --labels: list # list of label ids
  --milestone: int # milestone id (format: int64)
  --ref: string
  title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues")
  let body = {assignee: $assignee, assignees: $assignees, body: $body_body, closed: $closed, due_date: $due_date, labels: $labels, milestone: $milestone, ref: $ref, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all comments in a repository
#
# GET /repos/{owner}/{repo}/issues/comments
# operationId: issueGetRepoComments
export def "repos-issues-comments issueGetRepoComments" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # if provided, only comments updated since the provided time are returned. (format: date-time)
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a comment
#
# GET /repos/{owner}/{repo}/issues/comments/{id}
# operationId: issueGetComment
export def "repos-issues-comments issueGetComment" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}
# operationId: issueDeleteComment
export def "repos-issues-comments issueDeleteComment" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a comment
#
# PATCH /repos/{owner}/{repo}/issues/comments/{id}
# operationId: issueEditComment
export def "repos-issues-comments issueEditComment" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List comment's attachments
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/assets
# operationId: issueListIssueCommentAttachments
export def "repos-issues-comments-assets issueListIssueCommentAttachments" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/assets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a comment attachment
#
# POST /repos/{owner}/{repo}/issues/comments/{id}/assets
# operationId: issueCreateIssueCommentAttachment
export def "repos-issues-comments-assets issueCreateIssueCommentAttachment" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the attachment
  attachment: path # attachment to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/assets" $qp)
  let body = {attachment: $attachment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($attachment | is-not-empty) { $body | upsert attachment (open -r $attachment) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a comment attachment
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# operationId: issueGetIssueCommentAttachment
export def "repos-issues-comments-assets issueGetIssueCommentAttachment" [
  owner: string
  repo: string
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/assets/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment attachment
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# operationId: issueDeleteIssueCommentAttachment
export def "repos-issues-comments-assets issueDeleteIssueCommentAttachment" [
  owner: string
  repo: string
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/assets/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a comment attachment
#
# PATCH /repos/{owner}/{repo}/issues/comments/{id}/assets/{attachment_id}
# operationId: issueEditIssueCommentAttachment
export def "repos-issues-comments-assets issueEditIssueCommentAttachment" [
  owner: string
  repo: string
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name is the new filename for the attachment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/assets/($attachment_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of reactions from a comment of an issue
#
# GET /repos/{owner}/{repo}/issues/comments/{id}/reactions
# operationId: issueGetCommentReactions
export def "repos-issues-comments-reactions issueGetCommentReactions" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/reactions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a reaction to a comment of an issue
#
# POST /repos/{owner}/{repo}/issues/comments/{id}/reactions
# operationId: issuePostCommentReaction
export def "repos-issues-comments-reactions issuePostCommentReaction" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # The reaction content (e.g., emoji or reaction type)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/reactions")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a reaction from a comment of an issue
#
# DELETE /repos/{owner}/{repo}/issues/comments/{id}/reactions
# operationId: issueDeleteCommentReaction
export def "repos-issues-comments-reactions issueDeleteCommentReaction" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # The reaction content (e.g., emoji or reaction type)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/comments/($id)/reactions")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a repo's pinned issues
#
# GET /repos/{owner}/{repo}/issues/pinned
# operationId: repoListPinnedIssues
export def "repos-issues-pinned repoListPinnedIssues" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/pinned")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an issue
#
# GET /repos/{owner}/{repo}/issues/{index}
# operationId: issueGetIssue
export def "repos-issues issueGetIssue" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}
# operationId: issueDelete
export def "repos-issues issueDelete" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an issue. If using deadline only the date will be taken into account, and time of day ignored.
#
# PATCH /repos/{owner}/{repo}/issues/{index}
# operationId: issueEditIssue
export def "repos-issues issueEditIssue" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assignee: string # deprecated
  --assignees: list
  --body-body: string
  --content-version: int # The current version of the issue content to detect conflicts during editing (format: int64)
  --due-date: string # format: date-time
  --milestone: int # format: int64
  --ref: string
  --state: string
  --title: string
  --unset-due-date: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)")
  let body = {assignee: $assignee, assignees: $assignees, body: $body_body, content_version: $content_version, due_date: $due_date, milestone: $milestone, ref: $ref, state: $state, title: $title, unset_due_date: $unset_due_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List issue's attachments
#
# GET /repos/{owner}/{repo}/issues/{index}/assets
# operationId: issueListIssueAttachments
export def "repos-issues-assets issueListIssueAttachments" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/assets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an issue attachment
#
# POST /repos/{owner}/{repo}/issues/{index}/assets
# operationId: issueCreateIssueAttachment
export def "repos-issues-assets issueCreateIssueAttachment" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the attachment
  attachment: path # attachment to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/assets" $qp)
  let body = {attachment: $attachment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($attachment | is-not-empty) { $body | upsert attachment (open -r $attachment) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get an issue attachment
#
# GET /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# operationId: issueGetIssueAttachment
export def "repos-issues-assets issueGetIssueAttachment" [
  owner: string
  repo: string
  index: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/assets/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an issue attachment
#
# DELETE /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# operationId: issueDeleteIssueAttachment
export def "repos-issues-assets issueDeleteIssueAttachment" [
  owner: string
  repo: string
  index: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/assets/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an issue attachment
#
# PATCH /repos/{owner}/{repo}/issues/{index}/assets/{attachment_id}
# operationId: issueEditIssueAttachment
export def "repos-issues-assets issueEditIssueAttachment" [
  owner: string
  repo: string
  index: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name is the new filename for the attachment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/assets/($attachment_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List issues that are blocked by this issue
#
# GET /repos/{owner}/{repo}/issues/{index}/blocks
# operationId: issueListBlocks
export def "repos-issues-blocks issueListBlocks" [
  owner: string
  repo: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Block the issue given in the body by the issue in path
#
# POST /repos/{owner}/{repo}/issues/{index}/blocks
# operationId: issueCreateIssueBlocking
export def "repos-issues-blocks issueCreateIssueBlocking" [
  owner: string
  repo: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-index: int # format: int64
  --body-owner: string # owner of the issue's repo
  --body-repo: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/blocks")
  let body = {index: $body_index, owner: $body_owner, repo: $body_repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unblock the issue given in the body by the issue in path
#
# DELETE /repos/{owner}/{repo}/issues/{index}/blocks
# operationId: issueRemoveIssueBlocking
export def "repos-issues-blocks issueRemoveIssueBlocking" [
  owner: string
  repo: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-index: int # format: int64
  --body-owner: string # owner of the issue's repo
  --body-repo: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/blocks")
  let body = {index: $body_index, owner: $body_owner, repo: $body_repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all comments on an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/comments
# operationId: issueGetComments
export def "repos-issues-comments issueGetComments" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # if provided, only comments updated since the specified time are returned. (format: date-time)
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/comments
# operationId: issueCreateComment
export def "repos-issues-comments issueCreateComment" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/comments")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a comment
#
# DELETE /repos/{owner}/{repo}/issues/{index}/comments/{id}
# DEPRECATED
# operationId: issueDeleteCommentDeprecated
@deprecated
export def "repos-issues-comments issueDeleteCommentDeprecated" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/comments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a comment
#
# PATCH /repos/{owner}/{repo}/issues/{index}/comments/{id}
# DEPRECATED
# operationId: issueEditCommentDeprecated
@deprecated
export def "repos-issues-comments issueEditCommentDeprecated" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/comments/($id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set an issue deadline. If set to null, the deadline is deleted. If using deadline only the date will be taken into account, and time of day ignored.
#
# POST /repos/{owner}/{repo}/issues/{index}/deadline
# operationId: issueEditIssueDeadline
export def "repos-issues-deadline issueEditIssueDeadline" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  due_date: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/deadline")
  let body = {due_date: $due_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List an issue's dependencies, i.e all issues that block this issue.
#
# GET /repos/{owner}/{repo}/issues/{index}/dependencies
# operationId: issueListIssueDependencies
export def "repos-issues-dependencies issueListIssueDependencies" [
  owner: string
  repo: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/dependencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Make the issue in the url depend on the issue in the form.
#
# POST /repos/{owner}/{repo}/issues/{index}/dependencies
# operationId: issueCreateIssueDependencies
export def "repos-issues-dependencies issueCreateIssueDependencies" [
  owner: string
  repo: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-index: int # format: int64
  --body-owner: string # owner of the issue's repo
  --body-repo: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/dependencies")
  let body = {index: $body_index, owner: $body_owner, repo: $body_repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an issue dependency
#
# DELETE /repos/{owner}/{repo}/issues/{index}/dependencies
# operationId: issueRemoveIssueDependencies
export def "repos-issues-dependencies issueRemoveIssueDependencies" [
  owner: string
  repo: string
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-index: int # format: int64
  --body-owner: string # owner of the issue's repo
  --body-repo: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/dependencies")
  let body = {index: $body_index, owner: $body_owner, repo: $body_repo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an issue's labels
#
# GET /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueGetLabels
export def "repos-issues-labels issueGetLabels" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/labels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace an issue's labels
#
# PUT /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueReplaceLabels
export def "repos-issues-labels issueReplaceLabels" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: list # Labels can be a list of integers representing label IDs or a list of strings representing label names
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/labels")
  let body = {labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a label to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueAddLabel
export def "repos-issues-labels issueAddLabel" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --labels: list # Labels can be a list of integers representing label IDs or a list of strings representing label names
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/labels")
  let body = {labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove all labels from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/labels
# operationId: issueClearLabels
export def "repos-issues-labels issueClearLabels" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/labels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a label from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/labels/{id}
# operationId: issueRemoveLabel
export def "repos-issues-labels issueRemoveLabel" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock an issue
#
# PUT /repos/{owner}/{repo}/issues/{index}/lock
# operationId: issueLockIssue
export def "repos-issues-lock issueLockIssue" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lock-reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/lock")
  let body = {lock_reason: $lock_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlock an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/lock
# operationId: issueUnlockIssue
export def "repos-issues-lock issueUnlockIssue" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pin an Issue
#
# POST /repos/{owner}/{repo}/issues/{index}/pin
# operationId: pinIssue
export def "repos-issues-pin pinIssue" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/pin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpin an Issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/pin
# operationId: unpinIssue
export def "repos-issues-pin unpinIssue" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/pin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Moves the Pin to the given Position
#
# PATCH /repos/{owner}/{repo}/issues/{index}/pin/{position}
# operationId: moveIssuePin
export def "repos-issues-pin moveIssuePin" [
  owner: string
  repo: string
  index: int
  position: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/pin/($position)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list reactions of an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/reactions
# operationId: issueGetIssueReactions
export def "repos-issues-reactions issueGetIssueReactions" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/reactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a reaction to an issue
#
# POST /repos/{owner}/{repo}/issues/{index}/reactions
# operationId: issuePostIssueReaction
export def "repos-issues-reactions issuePostIssueReaction" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # The reaction content (e.g., emoji or reaction type)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/reactions")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a reaction from an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/reactions
# operationId: issueDeleteIssueReaction
export def "repos-issues-reactions issueDeleteIssueReaction" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # The reaction content (e.g., emoji or reaction type)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/reactions")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an issue's existing stopwatch.
#
# DELETE /repos/{owner}/{repo}/issues/{index}/stopwatch/delete
# operationId: issueDeleteStopWatch
export def "repos-issues-stopwatch-delete issueDeleteStopWatch" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/stopwatch/delete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start stopwatch on an issue.
#
# POST /repos/{owner}/{repo}/issues/{index}/stopwatch/start
# operationId: issueStartStopWatch
export def "repos-issues-stopwatch-start issueStartStopWatch" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/stopwatch/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop an issue's existing stopwatch.
#
# POST /repos/{owner}/{repo}/issues/{index}/stopwatch/stop
# operationId: issueStopStopWatch
export def "repos-issues-stopwatch-stop issueStopStopWatch" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/stopwatch/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users who subscribed on an issue.
#
# GET /repos/{owner}/{repo}/issues/{index}/subscriptions
# operationId: issueSubscriptions
export def "repos-issues-subscriptions issueSubscriptions" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if user is subscribed to an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/subscriptions/check
# operationId: issueCheckSubscription
export def "repos-issues-subscriptions-check issueCheckSubscription" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/subscriptions/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe user to issue
#
# PUT /repos/{owner}/{repo}/issues/{index}/subscriptions/{user}
# operationId: issueAddSubscription
export def "repos-issues-subscriptions issueAddSubscription" [
  owner: string
  repo: string
  index: int
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/subscriptions/($user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unsubscribe user from issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/subscriptions/{user}
# operationId: issueDeleteSubscription
export def "repos-issues-subscriptions issueDeleteSubscription" [
  owner: string
  repo: string
  index: int
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/subscriptions/($user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all comments and events on an issue
#
# GET /repos/{owner}/{repo}/issues/{index}/timeline
# operationId: issueGetCommentsAndTimeline
export def "repos-issues-timeline issueGetCommentsAndTimeline" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # if provided, only comments updated since the specified time are returned. (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --before: string # if provided, only comments updated before the provided time are returned. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an issue's tracked times
#
# GET /repos/{owner}/{repo}/issues/{index}/times
# operationId: issueTrackedTimes
export def "repos-issues-times issueTrackedTimes" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user: string # optional filter by user (available for issue managers)
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/times" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add tracked time to a issue
#
# POST /repos/{owner}/{repo}/issues/{index}/times
# operationId: issueAddTime
export def "repos-issues-times issueAddTime" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --created: string # format: date-time
  time: int # time in seconds (format: int64)
  --user-name: string # username of the user who spent the time working on the issue (optional)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/times")
  let body = {created: $created, time: $time, user_name: $user_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset a tracked time of an issue
#
# DELETE /repos/{owner}/{repo}/issues/{index}/times
# operationId: issueResetTime
export def "repos-issues-times issueResetTime" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/times")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete specific tracked time
#
# DELETE /repos/{owner}/{repo}/issues/{index}/times/{id}
# operationId: issueDeleteTime
export def "repos-issues-times issueDeleteTime" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/issues/($index)/times/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repository's keys
#
# GET /repos/{owner}/{repo}/keys
# operationId: repoListKeys
export def "repos-keys repoListKeys" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-id: int # the key_id to search for
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key_id" $key_id "scalar") (serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a key to a repository
#
# POST /repos/{owner}/{repo}/keys
# operationId: repoCreateKey
export def "repos-keys repoCreateKey" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/keys")
  let body = {key: $key, read_only: $read_only, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a repository's key by id
#
# GET /repos/{owner}/{repo}/keys/{id}
# operationId: repoGetKey
export def "repos-keys repoGetKey" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a key from a repository
#
# DELETE /repos/{owner}/{repo}/keys/{id}
# operationId: repoDeleteKey
export def "repos-keys repoDeleteKey" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all of a repository's labels
#
# GET /repos/{owner}/{repo}/labels
# operationId: issueListLabels
export def "repos-labels issueListLabels" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a label
#
# POST /repos/{owner}/{repo}/labels
# operationId: issueCreateLabel
export def "repos-labels issueCreateLabel" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  color: string # e.g. #00aabb
  --description: string # Description provides additional context about the label's purpose
  --exclusive: oneof<nothing, bool> # e.g. false
  --is-archived: oneof<nothing, bool> # e.g. false
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/labels")
  let body = {color: $color, description: $description, exclusive: $exclusive, is_archived: $is_archived, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single label
#
# GET /repos/{owner}/{repo}/labels/{id}
# operationId: issueGetLabel
export def "repos-labels issueGetLabel" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a label
#
# DELETE /repos/{owner}/{repo}/labels/{id}
# operationId: issueDeleteLabel
export def "repos-labels issueDeleteLabel" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a label
#
# PATCH /repos/{owner}/{repo}/labels/{id}
# operationId: issueEditLabel
export def "repos-labels issueEditLabel" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # e.g. #00aabb
  --description: string # Description provides additional context about the label's purpose
  --exclusive: oneof<nothing, bool> # e.g. false
  --is-archived: oneof<nothing, bool> # e.g. false
  --name: string # Name is the new display name for the label
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/labels/($id)")
  let body = {color: $color, description: $description, exclusive: $exclusive, is_archived: $is_archived, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get languages and number of bytes of code written
#
# GET /repos/{owner}/{repo}/languages
# operationId: repoGetLanguages
export def "repos-languages repoGetLanguages" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get repo licenses
#
# GET /repos/{owner}/{repo}/licenses
# operationId: repoGetLicenses
export def "repos-licenses repoGetLicenses" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/licenses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a file or it's LFS object from a repository
#
# GET /repos/{owner}/{repo}/media/{filepath}
# operationId: repoGetRawFileOrLFS
export def "repos-media repoGetRawFileOrLFS" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag. Default to the repository’s default branch
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/media/($filepath)" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge a branch from upstream
#
# POST /repos/{owner}/{repo}/merge-upstream
# operationId: repoMergeUpstream
export def "repos-merge-upstream repoMergeUpstream" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string
  --ff-only: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/merge-upstream")
  let body = {branch: $branch, ff_only: $ff_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all of a repository's opened milestones
#
# GET /repos/{owner}/{repo}/milestones
# operationId: issueGetMilestonesList
export def "repos-milestones issueGetMilestonesList" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string # Milestone state, Recognized values are open, closed and all. Defaults to "open"
  --name: string # filter by milestone name
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/milestones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a milestone
#
# POST /repos/{owner}/{repo}/milestones
# operationId: issueCreateMilestone
export def "repos-milestones issueCreateMilestone" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description provides details about the milestone
  --due-on: string # format: date-time
  --state: string@state-completer-2
  --title: string # Title is the title of the new milestone
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/milestones")
  let body = {description: $description, due_on: $due_on, state: $state, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a milestone
#
# GET /repos/{owner}/{repo}/milestones/{id}
# operationId: issueGetMilestone
export def "repos-milestones issueGetMilestone" [
  owner: string
  repo: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/milestones/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a milestone
#
# DELETE /repos/{owner}/{repo}/milestones/{id}
# operationId: issueDeleteMilestone
export def "repos-milestones issueDeleteMilestone" [
  owner: string
  repo: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/milestones/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a milestone
#
# PATCH /repos/{owner}/{repo}/milestones/{id}
# operationId: issueEditMilestone
export def "repos-milestones issueEditMilestone" [
  owner: string
  repo: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description provides updated details about the milestone
  --due-on: string # Deadline is the updated due date for the milestone (format: date-time)
  --state: string@state-completer-2 # State indicates the updated state of the milestone
  --title: string # Title is the updated title of the milestone
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/milestones/($id)")
  let body = {description: $description, due_on: $due_on, state: $state, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sync a mirrored repository
#
# POST /repos/{owner}/{repo}/mirror-sync
# operationId: repoMirrorSync
export def "repos-mirror-sync repoMirrorSync" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/mirror-sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns if new Issue Pins are allowed
#
# GET /repos/{owner}/{repo}/new_pin_allowed
# operationId: repoNewPinAllowed
export def "repos-new-pin-allowed repoNewPinAllowed" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/new_pin_allowed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users's notification threads on a specific repo
#
# GET /repos/{owner}/{repo}/notifications
# operationId: notifyGetRepoList
export def "repos-notifications notifyGetRepoList" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # If true, show notifications marked as read. Default value is false
  --status-types: list # Show notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread & pinned
  --subject-type: list # filter notifications by subject type
  --since: string # Only show notifications updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show notifications updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "subject-type" $subject_type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark notification threads as read, pinned or unread on a specific repo
#
# PUT /repos/{owner}/{repo}/notifications
# operationId: notifyReadRepoList
export def "repos-notifications notifyReadRepoList" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: string # If true, mark all notifications on this repo. Default value is false
  --status-types: list # Mark notifications with the provided status types. Options are: unread, read and/or pinned. Defaults to unread.
  --to-status: string # Status to mark notifications as. Defaults to read.
  --last-read-at: string # Describes the last point that notifications were checked. Anything updated since this time will not be updated. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "status-types" $status_types "multi") (serialize-qp "to-status" $to_status "scalar") (serialize-qp "last_read_at" $last_read_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repo's pull requests
#
# GET /repos/{owner}/{repo}/pulls
# operationId: repoListPullRequests
export def "repos-pulls repoListPullRequests" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-branch: string # Filter by target base branch of the pull request
  --state: string@state-completer # State of pull request (default: open)
  --qp-sort: string@sort-completer-1 # Type of sort
  --milestone: int # ID of the milestone (format: int64)
  --labels: list # Label IDs
  --poster: string # Filter by pull request author
  --page: int # Page number of results to return (1-based) (default: 1)
  --limit: int # Page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_branch" $base_branch "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "milestone" $milestone "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "poster" $poster "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a pull request
#
# POST /repos/{owner}/{repo}/pulls
# operationId: repoCreatePullRequest
export def "repos-pulls repoCreatePullRequest" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-maintainer-edit: oneof<nothing, bool> # Whether maintainers can edit the pull request
  --assignee: string # The primary assignee username
  --assignees: list # The list of assignee usernames
  --body-base: string # The base branch for the pull request
  --body-body: string # The description body of the pull request
  --due-date: string # format: date-time
  --head: string # The head branch for the pull request, it could be a branch name on the base repository or a form like `<username>:<branch>` which refers to the user's fork repository's branch.
  --labels: list # The list of label IDs to assign to the pull request
  --milestone: int # The milestone ID to assign to the pull request (format: int64)
  --reviewers: list # The list of reviewer usernames
  --team-reviewers: list # The list of team reviewer names
  --title: string # The title of the pull request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls")
  let body = {allow_maintainer_edit: $allow_maintainer_edit, assignee: $assignee, assignees: $assignees, base: $body_base, body: $body_body, due_date: $due_date, head: $head, labels: $labels, milestone: $milestone, reviewers: $reviewers, team_reviewers: $team_reviewers, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve a pull request review comment
#
# POST /repos/{owner}/{repo}/pulls/comments/{id}/resolve
# operationId: repoResolvePullReviewComment
export def "repos-pulls-comments-resolve repoResolvePullReviewComment" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/comments/($id)/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unresolve a pull request review comment
#
# POST /repos/{owner}/{repo}/pulls/comments/{id}/unresolve
# operationId: repoUnresolvePullReviewComment
export def "repos-pulls-comments-unresolve repoUnresolvePullReviewComment" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/comments/($id)/unresolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repo's pinned pull requests
#
# GET /repos/{owner}/{repo}/pulls/pinned
# operationId: repoListPinnedPullRequests
export def "repos-pulls-pinned repoListPinnedPullRequests" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/pinned")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pull request by base and head
#
# GET /repos/{owner}/{repo}/pulls/{base}/{head}
# operationId: repoGetPullRequestByBaseHead
export def "repos-pulls repoGetPullRequestByBaseHead" [
  owner: string
  repo: string
  base: string
  head: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($base)/($head)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}
# operationId: repoGetPullRequest
export def "repos-pulls repoGetPullRequest" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a pull request. If using deadline only the date will be taken into account, and time of day ignored.
#
# PATCH /repos/{owner}/{repo}/pulls/{index}
# operationId: repoEditPullRequest
export def "repos-pulls repoEditPullRequest" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-maintainer-edit: oneof<nothing, bool> # Whether to allow maintainer edits
  --assignee: string # The new primary assignee username
  --assignees: list # The new list of assignee usernames
  --body-base: string # The new base branch for the pull request
  --body-body: string # The new description body for the pull request
  --content-version: int # The current version of the pull request content to detect conflicts during editing (format: int64)
  --due-date: string # format: date-time
  --labels: list # The new list of label IDs for the pull request
  --milestone: int # The new milestone ID for the pull request (format: int64)
  --state: string # The new state for the pull request
  --title: string # The new title for the pull request
  --unset-due-date: oneof<nothing, bool> # Whether to remove the current deadline
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)")
  let body = {allow_maintainer_edit: $allow_maintainer_edit, assignee: $assignee, assignees: $assignees, base: $body_base, body: $body_body, content_version: $content_version, due_date: $due_date, labels: $labels, milestone: $milestone, state: $state, title: $title, unset_due_date: $unset_due_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a pull request diff or patch
#
# GET /repos/{owner}/{repo}/pulls/{index}.{diffType}
# operationId: repoDownloadPullDiffOrPatch
export def "repos-pulls repoDownloadPullDiffOrPatch" [
  owner: string
  repo: string
  index: int
  diffType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --binary: oneof<nothing, bool> # whether to include binary file changes. if true, the diff is applicable with `git apply`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "binary" $binary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index).($diffType)" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get commits for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/commits
# operationId: repoGetPullRequestCommits
export def "repos-pulls-commits repoGetPullRequestCommits" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --verification: oneof<nothing, bool> # include verification for every commit (disable for speedup, default 'true')
  --files: oneof<nothing, bool> # include a list of affected files for every commit (disable for speedup, default 'true')
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "verification" $verification "scalar") (serialize-qp "files" $files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/commits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get changed files for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/files
# operationId: repoGetPullRequestFiles
export def "repos-pulls-files repoGetPullRequestFiles" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --skip-to: string # skip to given file
  --whitespace: string@whitespace-completer # whitespace behavior
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip-to" $skip_to "scalar") (serialize-qp "whitespace" $whitespace "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a pull request has been merged
#
# GET /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoPullRequestIsMerged
export def "repos-pulls-merge repoPullRequestIsMerged" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/merge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoMergePullRequest
export def "repos-pulls-merge repoMergePullRequest" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-branch-after-merge: oneof<nothing, bool>
  --body-do: string@do-completer
  --force-merge: oneof<nothing, bool>
  --head-commit-id: string
  --merge-commit-id: string
  --merge-message-field: string
  --merge-title-field: string
  --merge-when-checks-succeed: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/merge")
  let body = {delete_branch_after_merge: $delete_branch_after_merge, do: $body_do, force_merge: $force_merge, head_commit_id: $head_commit_id, merge_commit_id: $merge_commit_id, merge_message_field: $merge_message_field, merge_title_field: $merge_title_field, merge_when_checks_succeed: $merge_when_checks_succeed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel the scheduled auto merge for the given pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/merge
# operationId: repoCancelScheduledAutoMerge
export def "repos-pulls-merge repoCancelScheduledAutoMerge" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/merge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# create review requests for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/requested_reviewers
# operationId: repoCreatePullReviewRequests
export def "repos-pulls-requested-reviewers repoCreatePullReviewRequests" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reviewers: list
  --team-reviewers: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/requested_reviewers")
  let body = {reviewers: $reviewers, team_reviewers: $team_reviewers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# cancel review requests for a pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/requested_reviewers
# operationId: repoDeletePullReviewRequests
export def "repos-pulls-requested-reviewers repoDeletePullReviewRequests" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reviewers: list
  --team-reviewers: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/requested_reviewers")
  let body = {reviewers: $reviewers, team_reviewers: $team_reviewers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all reviews for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews
# operationId: repoListPullReviews
export def "repos-pulls-reviews repoListPullReviews" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a review to an pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews
# operationId: repoCreatePullReview
# --comments item shape: {body?: string, new_position?: int, old_position?: int, path?: string}
export def "repos-pulls-reviews repoCreatePullReview" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
  --comments: list # item shape: {body?: string, new_position?: int, old_position?: int, path?: string}
  --commit-id: string
  --event: string@event-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews")
  let body = {body: $body_body, comments: $comments, commit_id: $commit_id, event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific review for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# operationId: repoGetPullReview
export def "repos-pulls-reviews repoGetPullReview" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit a pending review to an pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# operationId: repoSubmitPullReview
export def "repos-pulls-reviews repoSubmitPullReview" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string
  --event: string@event-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews/($id)")
  let body = {body: $body_body, event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific review from a pull request
#
# DELETE /repos/{owner}/{repo}/pulls/{index}/reviews/{id}
# operationId: repoDeletePullReview
export def "repos-pulls-reviews repoDeletePullReview" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific review for a pull request
#
# GET /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/comments
# operationId: repoGetPullReviewComments
export def "repos-pulls-reviews-comments repoGetPullReviewComments" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews/($id)/comments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dismiss a review for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/dismissals
# operationId: repoDismissPullReview
export def "repos-pulls-reviews-dismissals repoDismissPullReview" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string
  --priors: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews/($id)/dismissals")
  let body = {message: $message, priors: $priors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel to dismiss a review for a pull request
#
# POST /repos/{owner}/{repo}/pulls/{index}/reviews/{id}/undismissals
# operationId: repoUnDismissPullReview
export def "repos-pulls-reviews-undismissals repoUnDismissPullReview" [
  owner: string
  repo: string
  index: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/reviews/($id)/undismissals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge PR's baseBranch into headBranch
#
# POST /repos/{owner}/{repo}/pulls/{index}/update
# operationId: repoUpdatePullRequest
export def "repos-pulls-update repoUpdatePullRequest" [
  owner: string
  repo: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --style: string@style-completer # how to update pull request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "style" $style "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/pulls/($index)/update" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all push mirrors of the repository
#
# GET /repos/{owner}/{repo}/push_mirrors
# operationId: repoListPushMirrors
export def "repos-push-mirrors repoListPushMirrors" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/push_mirrors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# add a push mirror to the repository
#
# POST /repos/{owner}/{repo}/push_mirrors
# operationId: repoAddPushMirror
export def "repos-push-mirrors repoAddPushMirror" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --interval: string # The sync interval for automatic updates
  --remote-address: string # The remote repository URL to push to
  --remote-password: string # The password for authentication with the remote repository
  --remote-username: string # The username for authentication with the remote repository
  --sync-on-commit: oneof<nothing, bool> # Whether to sync on every commit
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/push_mirrors")
  let body = {interval: $interval, remote_address: $remote_address, remote_password: $remote_password, remote_username: $remote_username, sync_on_commit: $sync_on_commit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sync all push mirrored repository
#
# POST /repos/{owner}/{repo}/push_mirrors-sync
# operationId: repoPushMirrorSync
export def "repos-push-mirrors-sync repoPushMirrorSync" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/push_mirrors-sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get push mirror of the repository by remoteName
#
# GET /repos/{owner}/{repo}/push_mirrors/{name}
# operationId: repoGetPushMirrorByRemoteName
export def "repos-push-mirrors repoGetPushMirrorByRemoteName" [
  owner: string
  repo: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/push_mirrors/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# deletes a push mirror from a repository by remoteName
#
# DELETE /repos/{owner}/{repo}/push_mirrors/{name}
# operationId: repoDeletePushMirror
export def "repos-push-mirrors repoDeletePushMirror" [
  owner: string
  repo: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/push_mirrors/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a file from a repository
#
# GET /repos/{owner}/{repo}/raw/{filepath}
# operationId: repoGetRawFile
export def "repos-raw repoGetRawFile" [
  owner: string
  repo: string
  filepath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # The name of the commit/branch/tag. Default to the repository’s default branch
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/raw/($filepath)" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repo's releases
#
# GET /repos/{owner}/{repo}/releases
# operationId: repoListReleases
export def "repos-releases repoListReleases" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --draft: oneof<nothing, bool> # filter (exclude / include) drafts, if you don't have repo write access none will show
  --pre-release: oneof<nothing, bool> # filter (exclude / include) pre-releases
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "draft" $draft "scalar") (serialize-qp "pre-release" $pre_release "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a release
#
# POST /repos/{owner}/{repo}/releases
# operationId: repoCreateRelease
export def "repos-releases repoCreateRelease" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The release notes or description
  --draft: oneof<nothing, bool> # Whether to create the release as a draft
  --name: string # The display title of the release
  --prerelease: oneof<nothing, bool> # Whether to mark the release as a prerelease
  --tag-message: string # The message for the git tag
  tag_name: string
  --target-commitish: string # The target commitish for the release
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases")
  let body = {body: $body_body, draft: $draft, name: $name, prerelease: $prerelease, tag_message: $tag_message, tag_name: $tag_name, target_commitish: $target_commitish} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the most recent non-prerelease, non-draft release of a repository, sorted by created_at
#
# GET /repos/{owner}/{repo}/releases/latest
# operationId: repoGetLatestRelease
export def "repos-releases-latest repoGetLatestRelease" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a release by tag name
#
# GET /repos/{owner}/{repo}/releases/tags/{tag}
# operationId: repoGetReleaseByTag
export def "repos-releases-tags repoGetReleaseByTag" [
  owner: string
  repo: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/tags/($tag)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a release by tag name
#
# DELETE /repos/{owner}/{repo}/releases/tags/{tag}
# operationId: repoDeleteReleaseByTag
export def "repos-releases-tags repoDeleteReleaseByTag" [
  owner: string
  repo: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/tags/($tag)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a release
#
# GET /repos/{owner}/{repo}/releases/{id}
# operationId: repoGetRelease
export def "repos-releases repoGetRelease" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a release
#
# DELETE /repos/{owner}/{repo}/releases/{id}
# operationId: repoDeleteRelease
export def "repos-releases repoDeleteRelease" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a release
#
# PATCH /repos/{owner}/{repo}/releases/{id}
# operationId: repoEditRelease
export def "repos-releases repoEditRelease" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-body: string # The new release notes or description
  --draft: oneof<nothing, bool> # Whether to change the draft status
  --name: string # The new display title of the release
  --prerelease: oneof<nothing, bool> # Whether to change the prerelease status
  --tag-name: string # The new name of the git tag
  --target-commitish: string # The new target commitish for the release
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)")
  let body = {body: $body_body, draft: $draft, name: $name, prerelease: $prerelease, tag_name: $tag_name, target_commitish: $target_commitish} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List release's attachments
#
# GET /repos/{owner}/{repo}/releases/{id}/assets
# operationId: repoListReleaseAttachments
export def "repos-releases-assets repoListReleaseAttachments" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)/assets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a release attachment
#
# POST /repos/{owner}/{repo}/releases/{id}/assets
# operationId: repoCreateReleaseAttachment
export def "repos-releases-assets repoCreateReleaseAttachment" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the attachment
  --attachment: path # attachment to upload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)/assets" $qp)
  let body = {attachment: $attachment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($attachment | is-not-empty) { $body | upsert attachment (open -r $attachment) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a release attachment
#
# GET /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# operationId: repoGetReleaseAttachment
export def "repos-releases-assets repoGetReleaseAttachment" [
  owner: string
  repo: string
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)/assets/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a release attachment
#
# DELETE /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# operationId: repoDeleteReleaseAttachment
export def "repos-releases-assets repoDeleteReleaseAttachment" [
  owner: string
  repo: string
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)/assets/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a release attachment
#
# PATCH /repos/{owner}/{repo}/releases/{id}/assets/{attachment_id}
# operationId: repoEditReleaseAttachment
export def "repos-releases-assets repoEditReleaseAttachment" [
  owner: string
  repo: string
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name is the new filename for the attachment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/releases/($id)/assets/($attachment_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return all users that can be requested to review in this repo
#
# GET /repos/{owner}/{repo}/reviewers
# operationId: repoGetReviewers
export def "repos-reviewers repoGetReviewers" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/reviewers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get signing-key.gpg for given repository
#
# GET /repos/{owner}/{repo}/signing-key.gpg
# operationId: repoSigningKey
export def "repos-signing-keygpg repoSigningKey" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/signing-key.gpg")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get signing-key.pub for given repository
#
# GET /repos/{owner}/{repo}/signing-key.pub
# operationId: repoSigningKeySSH
export def "repos-signing-keypub repoSigningKeySSH" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/signing-key.pub")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repo's stargazers
#
# GET /repos/{owner}/{repo}/stargazers
# operationId: repoListStargazers
export def "repos-stargazers repoListStargazers" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/stargazers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit's statuses
#
# GET /repos/{owner}/{repo}/statuses/{sha}
# operationId: repoListStatuses
export def "repos-statuses repoListStatuses" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # type of sort
  --state: string@state-completer-1 # type of state
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/statuses/($sha)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a commit status
#
# POST /repos/{owner}/{repo}/statuses/{sha}
# operationId: repoCreateStatus
export def "repos-statuses repoCreateStatus" [
  owner: string
  repo: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --context: string # Context is the unique context identifier for the status
  --description: string # Description provides a brief description of the status
  --state: string@state-completer-3 # State represents the status state to set (pending, success, error, failure) pending CommitStatusPending  CommitStatusPending is for when the CommitStatus is Pending success CommitStatusSuccess  CommitStatusSuccess is for when the CommitStatus is Success error CommitStatusError  CommitStatusError is for when the CommitStatus is Error failure CommitStatusFailure  CommitStatusFailure is for when the CommitStatus is Failure warning CommitStatusWarning  CommitStatusWarning is for when the CommitStatus is Warning skipped CommitStatusSkipped  CommitStatusSkipped is for when CommitStatus is Skipped
  --target-url: string # TargetURL is the URL to link to for more details
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/statuses/($sha)")
  let body = {context: $context, description: $description, state: $state, target_url: $target_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a repo's watchers
#
# GET /repos/{owner}/{repo}/subscribers
# operationId: repoListSubscribers
export def "repos-subscribers repoListSubscribers" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if the current user is watching a repo
#
# GET /repos/{owner}/{repo}/subscription
# operationId: userCurrentCheckSubscription
export def "repos-subscription userCurrentCheckSubscription" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Watch a repo
#
# PUT /repos/{owner}/{repo}/subscription
# operationId: userCurrentPutSubscription
export def "repos-subscription userCurrentPutSubscription" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unwatch a repo
#
# DELETE /repos/{owner}/{repo}/subscription
# operationId: userCurrentDeleteSubscription
export def "repos-subscription userCurrentDeleteSubscription" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tag protections for a repository
#
# GET /repos/{owner}/{repo}/tag_protections
# operationId: repoListTagProtection
export def "repos-tag-protections repoListTagProtection" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tag_protections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tag protections for a repository
#
# POST /repos/{owner}/{repo}/tag_protections
# operationId: repoCreateTagProtection
export def "repos-tag-protections repoCreateTagProtection" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name-pattern: string # The pattern to match tag names for protection
  --whitelist-teams: list # List of team names allowed to create/delete protected tags
  --whitelist-usernames: list # List of usernames allowed to create/delete protected tags
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tag_protections")
  let body = {name_pattern: $name_pattern, whitelist_teams: $whitelist_teams, whitelist_usernames: $whitelist_usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a specific tag protection for the repository
#
# GET /repos/{owner}/{repo}/tag_protections/{id}
# operationId: repoGetTagProtection
export def "repos-tag-protections repoGetTagProtection" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tag_protections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a specific tag protection for the repository
#
# DELETE /repos/{owner}/{repo}/tag_protections/{id}
# operationId: repoDeleteTagProtection
export def "repos-tag-protections repoDeleteTagProtection" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tag_protections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a tag protections for a repository. Only fields that are set will be changed
#
# PATCH /repos/{owner}/{repo}/tag_protections/{id}
# operationId: repoEditTagProtection
export def "repos-tag-protections repoEditTagProtection" [
  owner: string
  repo: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name-pattern: string # The pattern to match tag names for protection
  --whitelist-teams: list # List of team names allowed to create/delete protected tags
  --whitelist-usernames: list # List of usernames allowed to create/delete protected tags
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tag_protections/($id)")
  let body = {name_pattern: $name_pattern, whitelist_teams: $whitelist_teams, whitelist_usernames: $whitelist_usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a repository's tags
#
# GET /repos/{owner}/{repo}/tags
# operationId: repoListTags
export def "repos-tags repoListTags" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results, default maximum page size is 50
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new git tag in a repository
#
# POST /repos/{owner}/{repo}/tags
# operationId: repoCreateTag
export def "repos-tags repoCreateTag" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string # The message to associate with the tag
  tag_name: string
  --target: string # The target commit SHA or branch name for the tag
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tags")
  let body = {message: $message, tag_name: $tag_name, target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the tag of a repository by tag name
#
# GET /repos/{owner}/{repo}/tags/{tag}
# operationId: repoGetTag
export def "repos-tags repoGetTag" [
  owner: string
  repo: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tags/($tag)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a repository's tag by name
#
# DELETE /repos/{owner}/{repo}/tags/{tag}
# operationId: repoDeleteTag
export def "repos-tags repoDeleteTag" [
  owner: string
  repo: string
  tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/tags/($tag)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repository's teams
#
# GET /repos/{owner}/{repo}/teams
# operationId: repoListTeams
export def "repos-teams repoListTeams" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a team is assigned to a repository
#
# GET /repos/{owner}/{repo}/teams/{team}
# operationId: repoCheckTeam
export def "repos-teams repoCheckTeam" [
  owner: string
  repo: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/teams/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a team to a repository
#
# PUT /repos/{owner}/{repo}/teams/{team}
# operationId: repoAddTeam
export def "repos-teams repoAddTeam" [
  owner: string
  repo: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/teams/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a team from a repository
#
# DELETE /repos/{owner}/{repo}/teams/{team}
# operationId: repoDeleteTeam
export def "repos-teams repoDeleteTeam" [
  owner: string
  repo: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/teams/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repo's tracked times
#
# GET /repos/{owner}/{repo}/times
# operationId: repoTrackedTimes
export def "repos-times repoTrackedTimes" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user: string # optional filter by user (available for issue managers)
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/times" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's tracked times in a repo
#
# GET /repos/{owner}/{repo}/times/{user}
# DEPRECATED
# operationId: userTrackedTimes
@deprecated
export def "repos-times userTrackedTimes" [
  owner: string
  repo: string
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/times/($user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of topics that a repository has
#
# GET /repos/{owner}/{repo}/topics
# operationId: repoListTopics
export def "repos-topics repoListTopics" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/topics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace list of topics for a repository
#
# PUT /repos/{owner}/{repo}/topics
# operationId: repoUpdateTopics
export def "repos-topics repoUpdateTopics" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --topics: list # list of topic names
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/topics")
  let body = {topics: $topics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a topic to a repository
#
# PUT /repos/{owner}/{repo}/topics/{topic}
# operationId: repoAddTopic
export def "repos-topics repoAddTopic" [
  owner: string
  repo: string
  topic: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/topics/($topic)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a topic from a repository
#
# DELETE /repos/{owner}/{repo}/topics/{topic}
# operationId: repoDeleteTopic
export def "repos-topics repoDeleteTopic" [
  owner: string
  repo: string
  topic: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/topics/($topic)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer a repo ownership
#
# POST /repos/{owner}/{repo}/transfer
# operationId: repoTransfer
export def "repos-transfer repoTransfer" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_owner: string
  --team-ids: list # ID of the team or teams to add to the repository. Teams can only be added to organization-owned repositories.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/transfer")
  let body = {new_owner: $new_owner, team_ids: $team_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Accept a repo transfer
#
# POST /repos/{owner}/{repo}/transfer/accept
# operationId: acceptRepoTransfer
export def "repos-transfer-accept acceptRepoTransfer" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/transfer/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reject a repo transfer
#
# POST /repos/{owner}/{repo}/transfer/reject
# operationId: rejectRepoTransfer
export def "repos-transfer-reject rejectRepoTransfer" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/transfer/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a wiki page
#
# POST /repos/{owner}/{repo}/wiki/new
# operationId: repoCreateWikiPage
export def "repos-wiki-new repoCreateWikiPage" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content-base64: string # content must be base64 encoded
  --message: string # optional commit message summarizing the change
  --title: string # page title. leave empty to keep unchanged
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/wiki/new")
  let body = {content_base64: $content_base64, message: $message, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a wiki page
#
# GET /repos/{owner}/{repo}/wiki/page/{pageName}
# operationId: repoGetWikiPage
export def "repos-wiki-page repoGetWikiPage" [
  owner: string
  repo: string
  pageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/wiki/page/($pageName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a wiki page
#
# DELETE /repos/{owner}/{repo}/wiki/page/{pageName}
# operationId: repoDeleteWikiPage
export def "repos-wiki-page repoDeleteWikiPage" [
  owner: string
  repo: string
  pageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/wiki/page/($pageName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a wiki page
#
# PATCH /repos/{owner}/{repo}/wiki/page/{pageName}
# operationId: repoEditWikiPage
export def "repos-wiki-page repoEditWikiPage" [
  owner: string
  repo: string
  pageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content-base64: string # content must be base64 encoded
  --message: string # optional commit message summarizing the change
  --title: string # page title. leave empty to keep unchanged
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($owner)/($repo)/wiki/page/($pageName)")
  let body = {content_base64: $content_base64, message: $message, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all wiki pages
#
# GET /repos/{owner}/{repo}/wiki/pages
# operationId: repoGetWikiPages
export def "repos-wiki-pages repoGetWikiPages" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/wiki/pages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get revisions of a wiki page
#
# GET /repos/{owner}/{repo}/wiki/revisions/{pageName}
# operationId: repoGetWikiPageRevisions
export def "repos-wiki-revisions repoGetWikiPageRevisions" [
  owner: string
  repo: string
  pageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repos/($owner)/($repo)/wiki/revisions/($pageName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a repository using a template
#
# POST /repos/{template_owner}/{template_repo}/generate
# operationId: generateRepo
export def "repos-generate generateRepo" [
  template_owner: string
  template_repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --avatar: oneof<nothing, bool> # include avatar of the template repo
  --default-branch: string # Default branch of the new repository
  --description: string # Description of the repository to create
  --git-content: oneof<nothing, bool> # include git content of default branch in template repo
  --git-hooks: oneof<nothing, bool> # include git hooks in template repo
  --labels: oneof<nothing, bool> # include labels in template repo
  name: string
  owner: string # the organization's name or individual user's name who will own the new repository
  --private: oneof<nothing, bool> # Whether the repository is private
  --protected-branch: oneof<nothing, bool> # include protected branches in template repo
  --topics: oneof<nothing, bool> # include topics in template repo
  --webhooks: oneof<nothing, bool> # include webhooks in template repo
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repos/($template_owner)/($template_repo)/generate")
  let body = {avatar: $avatar, default_branch: $default_branch, description: $description, git_content: $git_content, git_hooks: $git_hooks, labels: $labels, name: $name, owner: $owner, private: $private, protected_branch: $protected_branch, topics: $topics, webhooks: $webhooks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a repository by id
#
# GET /repositories/{id}
# operationId: repoGetByID
export def "repositories repoGetByID" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get instance's global settings for api
#
# GET /settings/api
# operationId: getGeneralAPISettings
export def "settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/api")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get instance's global settings for Attachment
#
# GET /settings/attachment
# operationId: getGeneralAttachmentSettings
export def "settings-attachment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/attachment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get instance's global settings for repositories
#
# GET /settings/repository
# operationId: getGeneralRepositorySettings
export def "settings-repository get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/repository")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get instance's global settings for ui
#
# GET /settings/ui
# operationId: getGeneralUISettings
export def "settings-ui get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/ui")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default signing-key.gpg
#
# GET /signing-key.gpg
# operationId: getSigningKey
export def "signing-keygpg get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signing-key.gpg")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get default signing-key.pub
#
# GET /signing-key.pub
# operationId: getSigningKeySSH
export def "signing-keypub get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signing-key.pub")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a team
#
# GET /teams/{id}
# operationId: orgGetTeam
export def "teams orgGetTeam" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a team
#
# DELETE /teams/{id}
# operationId: orgDeleteTeam
export def "teams orgDeleteTeam" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a team
#
# PATCH /teams/{id}
# operationId: orgEditTeam
export def "teams orgEditTeam" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --can-create-org-repo: oneof<nothing, bool> # Whether the team can create repositories in the organization
  --description: string # The description of the team
  --includes-all-repositories: oneof<nothing, bool> # Whether the team has access to all repositories in the organization
  name: string
  --permission: string@permission-completer
  --units: list # e.g. [repo.code, repo.issues, repo.ext_issues, repo.wiki, repo.pulls, repo.releases, repo.projects, repo.ext_wiki]
  --units-map: record # e.g. {repo.code: read, repo.ext_issues: none, repo.ext_wiki: none, repo.issues: write, repo.projects: none, repo.pulls: owner, repo.releases: none, repo.wiki: admin}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)")
  let body = {can_create_org_repo: $can_create_org_repo, description: $description, includes_all_repositories: $includes_all_repositories, name: $name, permission: $permission, units: $units, units_map: $units_map} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a team's activity feeds
#
# GET /teams/{id}/activities/feeds
# operationId: orgListTeamActivityFeeds
export def "teams-activities-feeds orgListTeamActivityFeeds" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # the date of the activities to be found (format: date)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($id)/activities/feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a team's members
#
# GET /teams/{id}/members
# operationId: orgListTeamMembers
export def "teams-members orgListTeamMembers" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a particular member of team
#
# GET /teams/{id}/members/{username}
# operationId: orgListTeamMember
export def "teams-members orgListTeamMember" [
  id: int
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a team member
#
# PUT /teams/{id}/members/{username}
# operationId: orgAddTeamMember
export def "teams-members orgAddTeamMember" [
  id: int
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a team member
#
# DELETE /teams/{id}/members/{username}
# operationId: orgRemoveTeamMember
export def "teams-members orgRemoveTeamMember" [
  id: int
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/members/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a team's repos
#
# GET /teams/{id}/repos
# operationId: orgListTeamRepos
export def "teams-repos orgListTeamRepos" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($id)/repos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a particular repo of team
#
# GET /teams/{id}/repos/{org}/{repo}
# operationId: orgListTeamRepo
export def "teams-repos orgListTeamRepo" [
  id: int
  org: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/repos/($org)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a repository to a team
#
# PUT /teams/{id}/repos/{org}/{repo}
# operationId: orgAddTeamRepository
export def "teams-repos orgAddTeamRepository" [
  id: int
  org: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/repos/($org)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a repository from a team
#
# DELETE /teams/{id}/repos/{org}/{repo}
# operationId: orgRemoveTeamRepository
export def "teams-repos orgRemoveTeamRepository" [
  id: int
  org: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($id)/repos/($org)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# search topics via keyword
#
# GET /topics/search
# operationId: topicSearch
export def "topics-search topicSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # keywords to search
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/topics/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the authenticated user
#
# GET /user
# operationId: userGetCurrent
export def "user userGetCurrent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workflow jobs
#
# GET /user/actions/jobs
# operationId: getUserWorkflowJobs
export def "user-actions-jobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/actions/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user-level runners
#
# GET /user/actions/runners
# operationId: getUserRunners
export def "user-actions-runners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool> # filter by disabled status (true or false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disabled" $disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/actions/runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an user's actions runner registration token
#
# POST /user/actions/runners/registration-token
# operationId: userCreateRunnerRegistrationToken
export def "user-actions-runners-registration-token userCreateRunnerRegistrationToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/actions/runners/registration-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user-level runner
#
# GET /user/actions/runners/{runner_id}
# operationId: getUserRunner
export def "user-actions-runners get" [
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user-level runner
#
# DELETE /user/actions/runners/{runner_id}
# operationId: deleteUserRunner
export def "user-actions-runners delete" [
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user-level runner
#
# PATCH /user/actions/runners/{runner_id}
# operationId: updateUserRunner
export def "user-actions-runners updateUserRunner" [
  runner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --disabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/runners/($runner_id)")
  let body = {disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get workflow runs
#
# GET /user/actions/runs
# operationId: getUserWorkflowRuns
export def "user-actions-runs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: string # workflow event name
  --branch: string # workflow branch
  --status: string # workflow status (pending, queued, in_progress, failure, success, skipped)
  --actor: string # triggered by user
  --head-sha: string # triggering sha of the workflow run
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "actor" $actor "scalar") (serialize-qp "head_sha" $head_sha "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/actions/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or Update a secret value in a user scope
#
# PUT /user/actions/secrets/{secretname}
# operationId: updateUserSecret
export def "user-actions-secrets updateUserSecret" [
  secretname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: string # Data of the secret to update
  --description: string # Description of the secret to update
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/secrets/($secretname)")
  let body = {data: $data, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a secret in a user scope
#
# DELETE /user/actions/secrets/{secretname}
# operationId: deleteUserSecret
export def "user-actions-secrets delete" [
  secretname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/secrets/($secretname)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the user-level list of variables which is created by current doer
#
# GET /user/actions/variables
# operationId: getUserVariablesList
export def "user-actions-variables list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/actions/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user-level variable which is created by current doer
#
# GET /user/actions/variables/{variablename}
# operationId: getUserVariable
export def "user-actions-variables get" [
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/variables/($variablename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user-level variable which is created by current doer
#
# PUT /user/actions/variables/{variablename}
# operationId: updateUserVariable
export def "user-actions-variables updateUserVariable" [
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the variable to update
  --name: string # New name for the variable. If the field is empty, the variable name won't be updated.
  value: string # Value of the variable to update
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/variables/($variablename)")
  let body = {description: $description, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a user-level variable
#
# POST /user/actions/variables/{variablename}
# operationId: createUserVariable
export def "user-actions-variables createUserVariable" [
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # Description of the variable to create
  value: string # Value of the variable to create
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/variables/($variablename)")
  let body = {description: $description, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user-level variable which is created by current doer
#
# DELETE /user/actions/variables/{variablename}
# operationId: deleteUserVariable
export def "user-actions-variables delete" [
  variablename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/actions/variables/($variablename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the authenticated user's oauth2 applications
#
# GET /user/applications/oauth2
# operationId: userGetOauth2Application
export def "user-applications-oauth2 userGetOauth2Application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/applications/oauth2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# creates a new OAuth2 application
#
# POST /user/applications/oauth2
# operationId: userCreateOAuth2Application
export def "user-applications-oauth2 userCreateOAuth2Application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confidential-client: oneof<nothing, bool> # Whether the client is confidential
  --name: string # The name of the OAuth2 application
  --redirect-uris: list # The list of allowed redirect URIs
  --skip-secondary-authorization: oneof<nothing, bool> # Whether to skip secondary authorization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/applications/oauth2")
  let body = {confidential_client: $confidential_client, name: $name, redirect_uris: $redirect_uris, skip_secondary_authorization: $skip_secondary_authorization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get an OAuth2 Application
#
# GET /user/applications/oauth2/{id}
# operationId: userGetOAuth2Application
export def "user-applications-oauth2 userGetOAuth2Application" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/applications/oauth2/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# delete an OAuth2 Application
#
# DELETE /user/applications/oauth2/{id}
# operationId: userDeleteOAuth2Application
export def "user-applications-oauth2 userDeleteOAuth2Application" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/applications/oauth2/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# update an OAuth2 Application, this includes regenerating the client secret
#
# PATCH /user/applications/oauth2/{id}
# operationId: userUpdateOAuth2Application
export def "user-applications-oauth2 userUpdateOAuth2Application" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confidential-client: oneof<nothing, bool> # Whether the client is confidential
  --name: string # The name of the OAuth2 application
  --redirect-uris: list # The list of allowed redirect URIs
  --skip-secondary-authorization: oneof<nothing, bool> # Whether to skip secondary authorization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/applications/oauth2/($id)")
  let body = {confidential_client: $confidential_client, name: $name, redirect_uris: $redirect_uris, skip_secondary_authorization: $skip_secondary_authorization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Avatar
#
# POST /user/avatar
# operationId: userUpdateAvatar
export def "user-avatar userUpdateAvatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --image: string # image must be base64 encoded
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/avatar")
  let body = {image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Avatar
#
# DELETE /user/avatar
# operationId: userDeleteAvatar
export def "user-avatar userDeleteAvatar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users blocked by the authenticated user
#
# GET /user/blocks
# operationId: userListBlocks
export def "user-blocks userListBlocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a user is blocked by the authenticated user
#
# GET /user/blocks/{username}
# operationId: userCheckUserBlock
export def "user-blocks userCheckUserBlock" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/blocks/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Block a user
#
# PUT /user/blocks/{username}
# operationId: userBlockUser
export def "user-blocks userBlockUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # optional note for the block
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "note" $note "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/blocks/($username)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unblock a user
#
# DELETE /user/blocks/{username}
# operationId: userUnblockUser
export def "user-blocks userUnblockUser" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/blocks/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the authenticated user's email addresses
#
# GET /user/emails
# operationId: userListEmails
export def "user-emails userListEmails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add email addresses
#
# POST /user/emails
# operationId: userAddEmail
export def "user-emails userAddEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emails: list # email addresses to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails")
  let body = {emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete email addresses
#
# DELETE /user/emails
# operationId: userDeleteEmail
export def "user-emails userDeleteEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emails: list # email addresses to delete
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails")
  let body = {emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the authenticated user's followers
#
# GET /user/followers
# operationId: userCurrentListFollowers
export def "user-followers userCurrentListFollowers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the users that the authenticated user is following
#
# GET /user/following
# operationId: userCurrentListFollowing
export def "user-following userCurrentListFollowing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check whether a user is followed by the authenticated user
#
# GET /user/following/{username}
# operationId: userCurrentCheckFollowing
export def "user-following userCurrentCheckFollowing" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/following/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Follow a user
#
# PUT /user/following/{username}
# operationId: userCurrentPutFollow
export def "user-following userCurrentPutFollow" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/following/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unfollow a user
#
# DELETE /user/following/{username}
# operationId: userCurrentDeleteFollow
export def "user-following userCurrentDeleteFollow" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/following/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Token to verify
#
# GET /user/gpg_key_token
# operationId: getVerificationToken
export def "user-gpg-key-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/gpg_key_token")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify a GPG key
#
# POST /user/gpg_key_verify
# operationId: userVerifyGPGKey
export def "user-gpg-key-verify userVerifyGPGKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/gpg_key_verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the authenticated user's GPG keys
#
# GET /user/gpg_keys
# operationId: userCurrentListGPGKeys
export def "user-gpg-keys userCurrentListGPGKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/gpg_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a GPG key
#
# POST /user/gpg_keys
# operationId: userCurrentPostGPGKey
export def "user-gpg-keys userCurrentPostGPGKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  armored_public_key: string # An armored GPG key to add
  --armored-signature: string # An optional armored signature for the GPG key
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/gpg_keys")
  let body = {armored_public_key: $armored_public_key, armored_signature: $armored_signature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a GPG key
#
# GET /user/gpg_keys/{id}
# operationId: userCurrentGetGPGKey
export def "user-gpg-keys userCurrentGetGPGKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/gpg_keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a GPG key
#
# DELETE /user/gpg_keys/{id}
# operationId: userCurrentDeleteGPGKey
export def "user-gpg-keys userCurrentDeleteGPGKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/gpg_keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the authenticated user's webhooks
#
# GET /user/hooks
# operationId: userListHooks
export def "user-hooks userListHooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a hook
#
# POST /user/hooks
# operationId: userCreateHook
export def "user-hooks userCreateHook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # default: false
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  config: record # CreateHookOptionConfig has all config options in it required are "content_type" and "url" Required
  --events: list # List of events that will trigger this webhook
  --name: string # Optional human-readable name for the webhook
  type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/hooks")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a hook
#
# GET /user/hooks/{id}
# operationId: userGetHook
export def "user-hooks userGetHook" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a hook
#
# DELETE /user/hooks/{id}
# operationId: userDeleteHook
export def "user-hooks userDeleteHook" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a hook
#
# PATCH /user/hooks/{id}
# operationId: userEditHook
export def "user-hooks userEditHook" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # Whether the webhook is active and will be triggered
  --authorization-header: string # Authorization header to include in webhook requests
  --branch-filter: string # Branch filter pattern to determine which branches trigger the webhook
  --config: record # Configuration settings for the webhook
  --events: list # List of events that trigger this webhook
  --name: string # Optional human-readable name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/hooks/($id)")
  let body = {active: $active, authorization_header: $authorization_header, branch_filter: $branch_filter, config: $config, events: $events, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the authenticated user's public keys
#
# GET /user/keys
# operationId: userCurrentListKeys
export def "user-keys userCurrentListKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a public key
#
# POST /user/keys
# operationId: userCurrentPostKey
export def "user-keys userCurrentPostKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # An armored SSH key to add
  --read-only: oneof<nothing, bool> # Describe if the key has only read access or read/write
  title: string # Title of the key to add
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/keys")
  let body = {key: $key, read_only: $read_only, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a public key
#
# GET /user/keys/{id}
# operationId: userCurrentGetKey
export def "user-keys userCurrentGetKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a public key
#
# DELETE /user/keys/{id}
# operationId: userCurrentDeleteKey
export def "user-keys userCurrentDeleteKey" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the current user's organizations
#
# GET /user/orgs
# operationId: orgListCurrentUserOrgs
export def "user-orgs orgListCurrentUserOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/orgs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the repos that the authenticated user owns
#
# GET /user/repos
# operationId: userCurrentListRepos
export def "user-repos userCurrentListRepos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/repos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a repository
#
# POST /user/repos
# operationId: createCurrentUserRepo
export def "user-repos createCurrentUserRepo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auto-init: oneof<nothing, bool> # Whether the repository should be auto-initialized?
  --default-branch: string # DefaultBranch of the repository (used when initializes and in template)
  --description: string # Description of the repository to create
  --gitignores: string # Gitignores to use
  --issue-labels: string # Label-Set to use
  --license: string # License to use
  name: string # Name of the repository to create
  --object-format-name: string@object-format-name-completer # ObjectFormatName of the underlying git repository, empty string for default (sha1)
  --private: oneof<nothing, bool> # Whether the repository is private
  --readme: string # Readme of the repository to create
  --template: oneof<nothing, bool> # Whether the repository is template
  --trust-model: string@trust-model-completer # TrustModel of the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/repos")
  let body = {auto_init: $auto_init, default_branch: $default_branch, description: $description, gitignores: $gitignores, issue_labels: $issue_labels, license: $license, name: $name, object_format_name: $object_format_name, private: $private, readme: $readme, template: $template, trust_model: $trust_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user settings
#
# GET /user/settings
# operationId: getUserSettings
export def "user-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user settings
#
# PATCH /user/settings
# operationId: updateUserSettings
export def "user-settings updateUserSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --diff-view-style: string
  --full-name: string
  --hide-activity: oneof<nothing, bool>
  --hide-email: oneof<nothing, bool> # Privacy
  --language: string
  --location: string
  --theme: string
  --website: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/settings")
  let body = {description: $description, diff_view_style: $diff_view_style, full_name: $full_name, hide_activity: $hide_activity, hide_email: $hide_email, language: $language, location: $location, theme: $theme, website: $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# The repos that the authenticated user has starred
#
# GET /user/starred
# operationId: userCurrentListStarred
export def "user-starred userCurrentListStarred" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/starred" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Whether the authenticated is starring the repo
#
# GET /user/starred/{owner}/{repo}
# operationId: userCurrentCheckStarring
export def "user-starred userCurrentCheckStarring" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/starred/($owner)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Star the given repo
#
# PUT /user/starred/{owner}/{repo}
# operationId: userCurrentPutStar
export def "user-starred userCurrentPutStar" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/starred/($owner)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unstar the given repo
#
# DELETE /user/starred/{owner}/{repo}
# operationId: userCurrentDeleteStar
export def "user-starred userCurrentDeleteStar" [
  owner: string
  repo: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/starred/($owner)/($repo)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of all existing stopwatches
#
# GET /user/stopwatches
# operationId: userGetStopWatches
export def "user-stopwatches userGetStopWatches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/stopwatches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repositories watched by the authenticated user
#
# GET /user/subscriptions
# operationId: userCurrentListSubscriptions
export def "user-subscriptions userCurrentListSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all the teams a user belongs to
#
# GET /user/teams
# operationId: userListTeams
export def "user-teams userListTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the current user's tracked times
#
# GET /user/times
# operationId: userCurrentTrackedTimes
export def "user-times userCurrentTrackedTimes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
  --since: string # Only show times updated after the given time. This is a timestamp in RFC 3339 format (format: date-time)
  --before: string # Only show times updated before the given time. This is a timestamp in RFC 3339 format (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/times" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for users
#
# GET /users/search
# operationId: userSearch
export def "users-search userSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # keyword
  --uid: int # ID of the user to search for (format: int64)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> record<data: table<active: bool, avatar_url: string, created: string, description: string, email: string, followers_count: int, following_count: int, full_name: string, html_url: string, id: int, is_admin: bool, language: string, last_login: string, location: string, login: string, login_name: string, prohibit_login: bool, restricted: bool, source_id: int, starred_repos_count: int, visibility: string, website: string>, ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "uid" $uid "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /users/{username}
# operationId: userGet
export def "users userGet" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's activity feeds
#
# GET /users/{username}/activities/feeds
# operationId: userListActivityFeeds
export def "users-activities-feeds userListActivityFeeds" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --only-performed-by: oneof<nothing, bool> # if true, only show actions performed by the requested user
  --date: string # the date of the activities to be found (format: date)
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "only-performed-by" $only_performed_by "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/activities/feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the given user's followers
#
# GET /users/{username}/followers
# operationId: userListFollowers
export def "users-followers userListFollowers" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the users that the given user is following
#
# GET /users/{username}/following
# operationId: userListFollowing
export def "users-following userListFollowing" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if one user is following another user
#
# GET /users/{username}/following/{target}
# operationId: userCheckFollowing
export def "users-following userCheckFollowing" [
  username: string
  target: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/following/($target)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the given user's GPG keys
#
# GET /users/{username}/gpg_keys
# operationId: userListGPGKeys
export def "users-gpg-keys userListGPGKeys" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/gpg_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's heatmap
#
# GET /users/{username}/heatmap
# operationId: userGetHeatmapData
export def "users-heatmap userGetHeatmapData" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/heatmap")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the given user's public keys
#
# GET /users/{username}/keys
# operationId: userListKeys
export def "users-keys userListKeys" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fingerprint: string # fingerprint of the key
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a user's organizations
#
# GET /users/{username}/orgs
# operationId: orgListUserOrgs
export def "users-orgs orgListUserOrgs" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/orgs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user permissions in organization
#
# GET /users/{username}/orgs/{org}/permissions
# operationId: orgGetUserPermissions
export def "users-orgs-permissions orgGetUserPermissions" [
  username: string
  org: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/orgs/($org)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the repos owned by the given user
#
# GET /users/{username}/repos
# operationId: userListRepos
export def "users-repos userListRepos" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/repos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The repos that the given user has starred
#
# GET /users/{username}/starred
# operationId: userListStarred
export def "users-starred userListStarred" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/starred" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the repositories watched by a user
#
# GET /users/{username}/subscriptions
# operationId: userListSubscriptions
export def "users-subscriptions userListSubscriptions" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the authenticated user's access tokens
#
# GET /users/{username}/tokens
# operationId: userGetTokens
export def "users-tokens userGetTokens" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # page number of results to return (1-based)
  --limit: int # page size of results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($username)/tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an access token
#
# POST /users/{username}/tokens
# operationId: userCreateToken
export def "users-tokens userCreateToken" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --scopes: list # e.g. [all, read:activitypub, read:issue, write:misc, read:notification, read:organization, read:package, read:repository, read:user]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/tokens")
  let body = {name: $name, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete an access token
#
# DELETE /users/{username}/tokens/{token}
# operationId: userDeleteAccessToken
export def "users-tokens userDeleteAccessToken" [
  username: string
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($username)/tokens/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the version of the Gitea application
#
# GET /version
# operationId: getVersion
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
