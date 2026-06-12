# Auto-generated client for Bitbucket API v2.0
# Source: https://api.bitbucket.org/swagger.json
# Auth: --token flag or $env.BITBUCKET_API_TOKEN

const BASE_URL = "https://api.bitbucket.org/2.0"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BITBUCKET_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.bitbucket.org/2.0"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def role-completer [] { ["admin" "contributor" "member" "owner"] }
def scm-completer [] { ["git"] }
def fork-policy-completer [] { ["allow_forks" "no_forks" "no_public_forks"] }
def kind-completer [] { ["allow_auto_merge_when_builds_pass" "delete" "enforce_merge_checks" "force" "push" "require_all_comments_resolved" "require_all_dependencies_merged" "require_approvals_to_merge" "require_commits_behind" "require_default_reviewer_approvals_to_merge" "require_no_changes_requested" "require_passing_builds_to_merge" "require_review_group_approvals_to_merge" "require_tasks_to_be_completed" "reset_pullrequest_approvals_on_change" "reset_pullrequest_changes_requested_on_change" "restrict_merges" "smart_reset_pullrequest_approvals"] }
def branch-match-kind-completer [] { ["branching_model" "glob"] }
def branch-type-completer [] { ["bugfix" "development" "feature" "hotfix" "production" "release"] }
def report-type-completer [] { ["BUG" "COVERAGE" "SECURITY" "TEST"] }
def result-completer [] { ["FAILED" "PASSED" "PENDING"] }
def annotation-type-completer [] { ["BUG" "CODE_SMELL" "VULNERABILITY"] }
def result-completer-1 [] { ["FAILED" "IGNORED" "PASSED" "SKIPPED"] }
def severity-completer [] { ["CRITICAL" "HIGH" "LOW" "MEDIUM"] }
def state-completer [] { ["FAILED" "INPROGRESS" "STOPPED" "SUCCESSFUL"] }
def state-completer-1 [] { ["closed" "duplicate" "invalid" "new" "on hold" "open" "resolved" "submitted" "wontfix"] }
def kind-completer-1 [] { ["bug" "enhancement" "proposal" "task"] }
def priority-completer [] { ["blocker" "critical" "major" "minor" "trivial"] }
def permission-completer [] { ["admin" "read" "write"] }
def targetref-type-completer [] { ["ANNOTATED_TAG" "BRANCH" "TAG"] }
def targetselectortype-completer [] { ["BRANCH" "CUSTOM" "DEFAULT" "PULLREQUESTS" "TAG"] }
def trigger-type-completer [] { ["MANUAL" "PARENT_STEP" "PUSH" "SCHEDULED"] }
def status-completer [] { ["BUILDING" "ERROR" "FAILED" "HALTED" "PARSING" "PASSED" "PAUSED" "PENDING" "STOPPED" "UNKNOWN"] }
def sort-completer [] { ["created_on" "creator.uuid" "run_creation_date"] }
def state-completer-2 [] { ["DECLINED" "MERGED" "OPEN" "SUPERSEDED"] }
def state-completer-3 [] { ["DECLINED" "DRAFT" "MERGED" "OPEN" "QUEUED" "SUPERSEDED"] }
def merge-strategy-completer [] { ["fast_forward" "merge_commit" "rebase_fast_forward" "rebase_merge" "squash" "squash_fast_forward"] }
def state-completer-4 [] { ["RESOLVED" "UNRESOLVED"] }
def format-completer [] { ["meta"] }
def format-completer-1 [] { ["meta" "rendered"] }
def role-completer-1 [] { ["contributor" "member" "owner"] }
def accept-completer [] { ["application/json" "multipart/form-data" "multipart/related"] }
def role-completer-2 [] { ["collaborator" "member" "owner"] }
def permission-completer-1 [] { ["admin" "create-repo" "read" "write"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addon delete" } } | get name | first)
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

# Delete an app
#
# DELETE /addon
export def "addon delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addon")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an installed app
#
# PUT /addon
export def "addon put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addon")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List linkers for an app
#
# GET /addon/linkers
# DEPRECATED
@deprecated
export def "addon-linkers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addon/linkers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a linker for an app
#
# GET /addon/linkers/{linker_key}
# DEPRECATED
@deprecated
export def "addon-linkers get" [
  linker_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/linkers/($linker_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all linker values
#
# DELETE /addon/linkers/{linker_key}/values
# DEPRECATED
@deprecated
export def "addon-linkers-values delete-by-linker_key" [
  linker_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/linkers/($linker_key)/values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List linker values for a linker
#
# GET /addon/linkers/{linker_key}/values
# DEPRECATED
@deprecated
export def "addon-linkers-values list" [
  linker_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/linkers/($linker_key)/values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a linker value
#
# POST /addon/linkers/{linker_key}/values
# DEPRECATED
@deprecated
export def "addon-linkers-values post" [
  linker_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/linkers/($linker_key)/values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a linker value
#
# PUT /addon/linkers/{linker_key}/values
# DEPRECATED
@deprecated
export def "addon-linkers-values put" [
  linker_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/linkers/($linker_key)/values")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a linker value
#
# DELETE /addon/linkers/{linker_key}/values/{value_id}
# DEPRECATED
@deprecated
export def "addon-linkers-values delete-by-linker_key-value_id" [
  linker_key: string
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/linkers/($linker_key)/values/($value_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a linker value
#
# GET /addon/linkers/{linker_key}/values/{value_id}
# DEPRECATED
@deprecated
export def "addon-linkers-values get" [
  linker_key: string
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/linkers/($linker_key)/values/($value_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the client key of a Connect addon
#
# GET /addon/{addon_key}/client-key
export def "addon-client-key get" [
  addon_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/addon/($addon_key)/client-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook resource
#
# GET /hook_events
export def "hook-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<repository: record<events: record<href: string, name: string>>, workspace: record<events: record<href: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hook_events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List subscribable webhook types
#
# GET /hook_events/{subject_type}
export def "hook-events get" [
  subject_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<event: string, category: string, label: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/hook_events/($subject_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List public repositories
#
# GET /repositories
# DEPRECATED
@deprecated
export def "repositories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Filter the results to include only repositories created on or after this [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601)  timestamp. Example: `YYYY-MM-DDTHH:mm:ss.sssZ`
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository.  * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). `role` parameter must also be specified.
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repositories in a workspace
#
# GET /repositories/{workspace}
export def "repositories get-by-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer #  Filters the result based on the authenticated user's role on each repository.  * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).         
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a repository
#
# DELETE /repositories/{workspace}/{repo_slug}
export def "repositories delete" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --redirect-to: string # If a repository has been moved to a new location, use this parameter to show users a friendly message in the Bitbucket UI that the repository has moved to a new location. However, a GET to this endpoint will still return a 404.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirect_to" $redirect_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a repository
#
# GET /repositories/{workspace}/{repo_slug}
export def "repositories get-by-repo_slug-workspace" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, avatar: record<href: string, name: string>, pullrequests: record<href: string, name: string>, commits: record<href: string, name: string>, forks: record<href: string, name: string>, watchers: record<href: string, name: string>, downloads: record<href: string, name: string>, clone: list<record>, hooks: record<href: string, name: string>>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record<self: record, commits: record, html: record>, name: string, target: record<repository: any, participants: list>, merge_strategies: list<string>, default_merge_strategy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a repository
#
# POST /repositories/{workspace}/{repo_slug}
# --links shape: {self?: record, html?: record, avatar?: record, pullrequests?: record, commits?: record, forks?: record, watchers?: record, downloads?: record, clone?: list, hooks?: record}
export def "repositories post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record, avatar?: record, pullrequests?: record, commits?: record, forks?: record, watchers?: record, downloads?: record, clone?: list, hooks?: record}
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --is-private: oneof<nothing, bool>
  --parent: any
  --scm: string@scm-completer
  --owner: any
  --name: string
  --description: string
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --size: int
  --language: string
  --has-issues: oneof<nothing, bool> #  The issue tracker for this repository is enabled. Issue Tracker features are not supported for repositories in workspaces administered through admin.atlassian.com.
  --has-wiki: oneof<nothing, bool> #  The wiki for this repository is enabled. Wiki features are not supported for repositories in workspaces administered through admin.atlassian.com.
  --fork-policy: string@fork-policy-completer #  Controls the rules for forking this repository.  * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot   be made public later) * **no_forks**: deny all forking
  --project: any
  --mainbranch: any
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, avatar: record<href: string, name: string>, pullrequests: record<href: string, name: string>, commits: record<href: string, name: string>, forks: record<href: string, name: string>, watchers: record<href: string, name: string>, downloads: record<href: string, name: string>, clone: list<record>, hooks: record<href: string, name: string>>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record<self: record, commits: record, html: record>, name: string, target: record<repository: any, participants: list>, merge_strategies: list<string>, default_merge_strategy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)")
  let body = {type: $type, links: $links, uuid: $uuid, full_name: $full_name, is_private: $is_private, parent: $parent, scm: $scm, owner: $owner, name: $name, description: $description, created_on: $created_on, updated_on: $updated_on, size: $size, language: $language, has_issues: $has_issues, has_wiki: $has_wiki, fork_policy: $fork_policy, project: $project, mainbranch: $mainbranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a repository
#
# PUT /repositories/{workspace}/{repo_slug}
# --links shape: {self?: record, html?: record, avatar?: record, pullrequests?: record, commits?: record, forks?: record, watchers?: record, downloads?: record, clone?: list, hooks?: record}
export def "repositories put" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record, avatar?: record, pullrequests?: record, commits?: record, forks?: record, watchers?: record, downloads?: record, clone?: list, hooks?: record}
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --is-private: oneof<nothing, bool>
  --parent: any
  --scm: string@scm-completer
  --owner: any
  --name: string
  --description: string
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --size: int
  --language: string
  --has-issues: oneof<nothing, bool> #  The issue tracker for this repository is enabled. Issue Tracker features are not supported for repositories in workspaces administered through admin.atlassian.com.
  --has-wiki: oneof<nothing, bool> #  The wiki for this repository is enabled. Wiki features are not supported for repositories in workspaces administered through admin.atlassian.com.
  --fork-policy: string@fork-policy-completer #  Controls the rules for forking this repository.  * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot   be made public later) * **no_forks**: deny all forking
  --project: any
  --mainbranch: any
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, avatar: record<href: string, name: string>, pullrequests: record<href: string, name: string>, commits: record<href: string, name: string>, forks: record<href: string, name: string>, watchers: record<href: string, name: string>, downloads: record<href: string, name: string>, clone: list<record>, hooks: record<href: string, name: string>>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record<self: record, commits: record, html: record>, name: string, target: record<repository: any, participants: list>, merge_strategies: list<string>, default_merge_strategy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)")
  let body = {type: $type, links: $links, uuid: $uuid, full_name: $full_name, is_private: $is_private, parent: $parent, scm: $scm, owner: $owner, name: $name, description: $description, created_on: $created_on, updated_on: $updated_on, size: $size, language: $language, has_issues: $has_issues, has_wiki: $has_wiki, fork_policy: $fork_policy, project: $project, mainbranch: $mainbranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List branch restrictions
#
# GET /repositories/{workspace}/{repo_slug}/branch-restrictions
export def "repositories-branch-restrictions list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --kind: string # Branch restrictions of this type
  --pattern: string # Branch restrictions applied to branches of this pattern
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, id: int, kind: string, branch_match_kind: string, branch_type: string, pattern: string, value: int, users: list, groups: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kind" $kind "scalar") (serialize-qp "pattern" $pattern "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branch-restrictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a branch restriction rule
#
# POST /repositories/{workspace}/{repo_slug}/branch-restrictions
# --links shape: {self?: record}
# --users item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
# --groups item shape: {type: string, links?: record, owner?: any, workspace?: any, name?: string, slug?: string, full_slug?: string}
export def "repositories-branch-restrictions post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record}
  --id: int # The branch restriction status' id.
  kind: string@kind-completer # The type of restriction that is being applied.
  branch_match_kind: string@branch-match-kind-completer # Indicates how the restriction is matched against a branch. The default is `glob`.
  --branch-type: string@branch-type-completer # Apply the restriction to branches of this type. Active when `branch_match_kind` is `branching_model`. The branch type will be calculated using the branching model configured for the repository.
  pattern: string # Apply the restriction to branches that match this pattern. Active when `branch_match_kind` is `glob`. Will be empty when `branch_match_kind` is `branching_model`.
  --value: int # Value with kind-specific semantics:  * `require_approvals_to_merge` uses it to require a minimum number of approvals on a PR.  * `require_default_reviewer_approvals_to_merge` uses it to require a minimum number of approvals from default reviewers on a PR.  * `require_passing_builds_to_merge` uses it to require a minimum number of passing builds.  * `require_commits_behind` uses it to require the current branch is up to a maximum number of commits behind it destination.
  --users: list # item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
  --groups: list # item shape: {type: string, links?: record, owner?: any, workspace?: any, name?: string, slug?: string, full_slug?: string}
]: any -> record<type: string, links: record<self: record<href: string, name: string>>, id: int, kind: string, branch_match_kind: string, branch_type: string, pattern: string, value: int, users: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, groups: table<type: string, links: record, owner: record, workspace: record, name: string, slug: string, full_slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branch-restrictions")
  let body = {type: $type, links: $links, id: $id, kind: $kind, branch_match_kind: $branch_match_kind, branch_type: $branch_type, pattern: $pattern, value: $value, users: $users, groups: $groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a branch restriction rule
#
# DELETE /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
export def "repositories-branch-restrictions delete" [
  id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branch-restrictions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a branch restriction rule
#
# GET /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
export def "repositories-branch-restrictions get" [
  id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, id: int, kind: string, branch_match_kind: string, branch_type: string, pattern: string, value: int, users: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, groups: table<type: string, links: record, owner: record, workspace: record, name: string, slug: string, full_slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branch-restrictions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a branch restriction rule
#
# PUT /repositories/{workspace}/{repo_slug}/branch-restrictions/{id}
# --links shape: {self?: record}
# --users item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
# --groups item shape: {type: string, links?: record, owner?: any, workspace?: any, name?: string, slug?: string, full_slug?: string}
export def "repositories-branch-restrictions put" [
  id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record}
  --body-id: int # The branch restriction status' id.
  kind: string@kind-completer # The type of restriction that is being applied.
  branch_match_kind: string@branch-match-kind-completer # Indicates how the restriction is matched against a branch. The default is `glob`.
  --branch-type: string@branch-type-completer # Apply the restriction to branches of this type. Active when `branch_match_kind` is `branching_model`. The branch type will be calculated using the branching model configured for the repository.
  pattern: string # Apply the restriction to branches that match this pattern. Active when `branch_match_kind` is `glob`. Will be empty when `branch_match_kind` is `branching_model`.
  --value: int # Value with kind-specific semantics:  * `require_approvals_to_merge` uses it to require a minimum number of approvals on a PR.  * `require_default_reviewer_approvals_to_merge` uses it to require a minimum number of approvals from default reviewers on a PR.  * `require_passing_builds_to_merge` uses it to require a minimum number of passing builds.  * `require_commits_behind` uses it to require the current branch is up to a maximum number of commits behind it destination.
  --users: list # item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
  --groups: list # item shape: {type: string, links?: record, owner?: any, workspace?: any, name?: string, slug?: string, full_slug?: string}
]: any -> record<type: string, links: record<self: record<href: string, name: string>>, id: int, kind: string, branch_match_kind: string, branch_type: string, pattern: string, value: int, users: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, groups: table<type: string, links: record, owner: record, workspace: record, name: string, slug: string, full_slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branch-restrictions/($id)")
  let body = {type: $type, links: $links, id: $body_id, kind: $kind, branch_match_kind: $branch_match_kind, branch_type: $branch_type, pattern: $pattern, value: $value, users: $users, groups: $groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the branching model for a repository
#
# GET /repositories/{workspace}/{repo_slug}/branching-model
export def "repositories-branching-model get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>, name: string, use_mainbranch: bool>, production: record<branch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branching-model")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the branching model config for a repository
#
# GET /repositories/{workspace}/{repo_slug}/branching-model/settings
export def "repositories-branching-model-settings get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, production: record<is_valid: bool, name: string, use_mainbranch: bool, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branching-model/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the branching model config for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/branching-model/settings
export def "repositories-branching-model-settings put" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, production: record<is_valid: bool, name: string, use_mainbranch: bool, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/branching-model/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}
export def "repositories-commit get" [
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: any, merge_strategies: list, default_merge_strategy: string>>, participants: table<type: string, user: record, role: string, approved: bool, state: string, participated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unapprove a commit
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/approve
export def "repositories-commit-approve delete" [
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/approve
export def "repositories-commit-approve post" [
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, role: string, approved: bool, state: string, participated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a commit's comments
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/comments
export def "repositories-commit-comments list" [
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<commit: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create comment for a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/comments
export def "repositories-commit-comments post" [
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-commit: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/comments")
  let body = {commit: $body_commit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a commit comment
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "repositories-commit-comments delete" [
  comment_id: int
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit comment
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "repositories-commit-comments get" [
  comment_id: int
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commit: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, participants: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a commit comment
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/comments/{comment_id}
export def "repositories-commit-comments put" [
  comment_id: int
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-commit: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/comments/($comment_id)")
  let body = {commit: $body_commit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a commit application property
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: updateCommitHostedPropertyValue
export def "repositories-commit-properties updateCommitHostedPropertyValue" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/properties/($app_key)/($property_name)")
  let body = {_attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a commit application property
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: deleteCommitHostedPropertyValue
export def "repositories-commit-properties delete" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a commit application property
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/properties/{app_key}/{property_name}
# operationId: getCommitHostedPropertyValue
export def "repositories-commit-properties get" [
  workspace: string
  repo_slug: string
  commit: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pull requests that contain a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/pullrequests
# operationId: getPullrequestsForCommit
export def "repositories-commit-pullrequests get" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Which page to retrieve (format: int32, default: 1)
  --pagelen: int # How many pull requests to retrieve per page (format: int32, default: 30)
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, id: int, title: string, rendered: record, summary: record, state: string, author: record, source: record, destination: record, merge_commit: record, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record, reason: string, created_on: string, updated_on: string, reviewers: list, participants: list, draft: bool, queued: bool, mergeable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/pullrequests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List reports
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports
# operationId: getReportsForCommit
export def "repositories-commit-reports list" [
  workspace: string
  repo_slug: string
  commit: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, title: string, details: string, external_id: string, reporter: string, link: string, remote_link_enabled: bool, logo_url: string, report_type: string, result: string, data: list, created_on: string, updated_on: string>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a report
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# operationId: createOrUpdateReport
# --data item shape: {type?: "BOOLEAN"|"DATE"|"DURATION"|"LINK"|"NUMBER"|"PERCENTAGE"|"TEXT", title?: string, value?: record}
export def "repositories-commit-reports createOrUpdateReport" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID that can be used to identify the report.
  --title: string # The title of the report.
  --details: string # A string to describe the purpose of the report.
  --external-id: string # ID of the report provided by the report creator. It can be used to identify the report as an alternative to it's generated uuid. It is not used by Bitbucket, but only by the report creator for updating or deleting this specific report. Needs to be unique.
  --reporter: string # A string to describe the tool or company who created the report.
  --link: string # A URL linking to the results of the report in an external tool. (format: uri)
  --remote-link-enabled: oneof<nothing, bool> # If enabled, a remote link is created in Jira for the work item associated with the commit the report belongs to.
  --logo-url: string # A URL to the report logo. If none is provided, the default insights logo will be used. (format: uri)
  --report-type: string@report-type-completer # The type of the report.
  --body-result: string@result-completer # The state of the report. May be set to PENDING and later updated.
  --data: list # An array of data fields to display information on the report. Maximum 10. — item shape: {type?: "BOOLEAN"|"DATE"|"DURATION"|"LINK"|"NUMBER"|"PERCENTAGE"|"TEXT", title?: string, value?: record}
  --created-on: string # The timestamp when the report was created. (format: date-time)
  --updated-on: string # The timestamp when the report was updated. (format: date-time)
]: any -> record<type: string, uuid: string, title: string, details: string, external_id: string, reporter: string, link: string, remote_link_enabled: bool, logo_url: string, report_type: string, result: string, data: table<type: string, title: string, value: record>, created_on: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)")
  let body = {type: $type, uuid: $uuid, title: $title, details: $details, external_id: $external_id, reporter: $reporter, link: $link, remote_link_enabled: $remote_link_enabled, logo_url: $logo_url, report_type: $report_type, result: $body_result, data: $data, created_on: $created_on, updated_on: $updated_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a report
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# operationId: getReport
export def "repositories-commit-reports get" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, title: string, details: string, external_id: string, reporter: string, link: string, remote_link_enabled: bool, logo_url: string, report_type: string, result: string, data: table<type: string, title: string, value: record>, created_on: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a report
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}
# operationId: deleteReport
export def "repositories-commit-reports delete" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List annotations
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations
# operationId: getAnnotationsForReport
export def "repositories-commit-reports-annotations list" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, external_id: string, uuid: string, annotation_type: string, path: string, line: int, summary: string, details: string, result: string, severity: string, link: string, created_on: string, updated_on: string>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)/annotations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk create or update annotations
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations
# operationId: bulkCreateOrUpdateAnnotations
export def "repositories-commit-reports-annotations bulkCreateOrUpdateAnnotations" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<type: string, external_id: string, uuid: string, annotation_type: string, path: string, line: int, summary: string, details: string, result: string, severity: string, link: string, created_on: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)/annotations")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an annotation
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# operationId: getAnnotation
export def "repositories-commit-reports-annotations get" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  annotationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, external_id: string, uuid: string, annotation_type: string, path: string, line: int, summary: string, details: string, result: string, severity: string, link: string, created_on: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)/annotations/($annotationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update an annotation
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# operationId: createOrUpdateAnnotation
export def "repositories-commit-reports-annotations createOrUpdateAnnotation" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  annotationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --external-id: string # ID of the annotation provided by the annotation creator. It can be used to identify the annotation as an alternative to it's generated uuid. It is not used by Bitbucket, but only by the annotation creator for updating or deleting this specific annotation. Needs to be unique.
  --uuid: string # The UUID that can be used to identify the annotation.
  --annotation-type: string@annotation-type-completer # The type of the report.
  --path: string # The path of the file on which this annotation should be placed. This is the path of the file relative to the git repository. If no path is provided, then it will appear in the overview modal on all pull requests where the tip of the branch is the given commit, regardless of which files were modified.
  --line: int # The line number that the annotation should belong to. If no line number is provided, then it will default to 0 and in a pull request it will appear at the top of the file specified by the path field.
  --summary: string # The message to display to users.
  --details: string # The details to show to users when clicking on the annotation.
  --body-result: string@result-completer-1 # The state of the report. May be set to PENDING and later updated.
  --severity: string@severity-completer # The severity of the annotation.
  --link: string # A URL linking to the annotation in an external tool. (format: uri)
  --created-on: string # The timestamp when the report was created. (format: date-time)
  --updated-on: string # The timestamp when the report was updated. (format: date-time)
]: any -> record<type: string, external_id: string, uuid: string, annotation_type: string, path: string, line: int, summary: string, details: string, result: string, severity: string, link: string, created_on: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)/annotations/($annotationId)")
  let body = {type: $type, external_id: $external_id, uuid: $uuid, annotation_type: $annotation_type, path: $path, line: $line, summary: $summary, details: $details, result: $body_result, severity: $severity, link: $link, created_on: $created_on, updated_on: $updated_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an annotation
#
# DELETE /repositories/{workspace}/{repo_slug}/commit/{commit}/reports/{reportId}/annotations/{annotationId}
# operationId: deleteAnnotation
export def "repositories-commit-reports-annotations delete" [
  workspace: string
  repo_slug: string
  commit: string
  reportId: string
  annotationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/reports/($reportId)/annotations/($annotationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commit statuses for a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses
export def "repositories-commit-statuses get" [
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refname: string # If specified, only return commit status objects that were either created without a refname, or were created with the specified refname
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). Defaults to `created_on`.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, key: string, refname: string, url: string, state: string, name: string, description: string, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refname" $refname "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a build status for a commit
#
# POST /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build
# --links shape: {self?: record, commit?: record}
export def "repositories-commit-statuses-build post" [
  commit: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, commit?: record}
  key: string # An identifier for the status that's unique to         its type (current "build" is the only supported type) and the vendor,         e.g. BB-DEPLOY
  --refname: string #  The name of the ref that pointed to this commit at the time the status object was created. Note that this the ref may since have moved off of the commit. This optional field can be useful for build systems whose build triggers and configuration are branch-dependent (e.g. a Pipeline build). It is legitimate for this field to not be set, or even apply (e.g. a static linting job).
  --body-url: string # A URL linking back to the vendor or build system, for providing more information about whatever process produced this status. Accepts context variables `repository` and `commit` that Bitbucket will evaluate at runtime whenever at runtime. For example, one could use https://foo.com/builds/{repository.full_name} which Bitbucket will turn into https://foo.com/builds/foo/bar at render time.
  state: string@state-completer # Provides some indication of the status of this commit
  --name: string # An identifier for the build itself, e.g. BB-DEPLOY-1
  --description: string # A description of the build (e.g. "Unit tests in Bamboo")
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
]: any -> record<type: string, links: record<self: record<href: string, name: string>, commit: record<href: string, name: string>>, key: string, refname: string, url: string, state: string, name: string, description: string, created_on: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/statuses/build")
  let body = {type: $type, links: $links, key: $key, refname: $refname, url: $body_url, state: $state, name: $name, description: $description, created_on: $created_on, updated_on: $updated_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a build status for a commit
#
# GET /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}
export def "repositories-commit-statuses-build get" [
  commit: string
  key: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, commit: record<href: string, name: string>>, key: string, refname: string, url: string, state: string, name: string, description: string, created_on: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/statuses/build/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a build status for a commit
#
# PUT /repositories/{workspace}/{repo_slug}/commit/{commit}/statuses/build/{key}
# --links shape: {self?: record, commit?: record}
export def "repositories-commit-statuses-build put" [
  commit: string
  key: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, commit?: record}
  --body-key: string # An identifier for the status that's unique to         its type (current "build" is the only supported type) and the vendor,         e.g. BB-DEPLOY
  --refname: string #  The name of the ref that pointed to this commit at the time the status object was created. Note that this the ref may since have moved off of the commit. This optional field can be useful for build systems whose build triggers and configuration are branch-dependent (e.g. a Pipeline build). It is legitimate for this field to not be set, or even apply (e.g. a static linting job).
  --body-url: string # A URL linking back to the vendor or build system, for providing more information about whatever process produced this status. Accepts context variables `repository` and `commit` that Bitbucket will evaluate at runtime whenever at runtime. For example, one could use https://foo.com/builds/{repository.full_name} which Bitbucket will turn into https://foo.com/builds/foo/bar at render time.
  state: string@state-completer # Provides some indication of the status of this commit
  --name: string # An identifier for the build itself, e.g. BB-DEPLOY-1
  --description: string # A description of the build (e.g. "Unit tests in Bamboo")
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
]: any -> record<type: string, links: record<self: record<href: string, name: string>, commit: record<href: string, name: string>>, key: string, refname: string, url: string, state: string, name: string, description: string, created_on: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commit/($commit)/statuses/build/($key)")
  let body = {type: $type, links: $links, key: $body_key, refname: $refname, url: $body_url, state: $state, name: $name, description: $description, created_on: $created_on, updated_on: $updated_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List commits
#
# GET /repositories/{workspace}/{repo_slug}/commits
export def "repositories-commits list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, hash: string, date: string, author: record, committer: record, message: string, summary: record, parents: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commits with include/exclude
#
# POST /repositories/{workspace}/{repo_slug}/commits
export def "repositories-commits post-by-repo_slug-workspace" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, hash: string, date: string, author: record, committer: record, message: string, summary: record, parents: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commits for revision
#
# GET /repositories/{workspace}/{repo_slug}/commits/{revision}
export def "repositories-commits get" [
  repo_slug: string
  revision: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, hash: string, date: string, author: record, committer: record, message: string, summary: record, parents: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commits/($revision)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commits for revision using include/exclude
#
# POST /repositories/{workspace}/{repo_slug}/commits/{revision}
export def "repositories-commits post-by-repo_slug-revision-workspace" [
  repo_slug: string
  revision: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, hash: string, date: string, author: record, committer: record, message: string, summary: record, parents: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/commits/($revision)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List components
#
# GET /repositories/{workspace}/{repo_slug}/components
# DEPRECATED
@deprecated
export def "repositories-components list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/components")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a component for issues
#
# GET /repositories/{workspace}/{repo_slug}/components/{component_id}
# DEPRECATED
@deprecated
export def "repositories-components get" [
  component_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, name: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/components/($component_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List default reviewers
#
# GET /repositories/{workspace}/{repo_slug}/default-reviewers
export def "repositories-default-reviewers list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/default-reviewers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a user from the default reviewers
#
# DELETE /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
export def "repositories-default-reviewers delete" [
  repo_slug: string
  target_username: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/default-reviewers/($target_username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a default reviewer
#
# GET /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
export def "repositories-default-reviewers get" [
  repo_slug: string
  target_username: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<avatar: record<href: string, name: string>>, created_on: string, display_name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/default-reviewers/($target_username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a user to the default reviewers
#
# PUT /repositories/{workspace}/{repo_slug}/default-reviewers/{target_username}
export def "repositories-default-reviewers put" [
  repo_slug: string
  target_username: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<avatar: record<href: string, name: string>>, created_on: string, display_name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/default-reviewers/($target_username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repository deploy keys
#
# GET /repositories/{workspace}/{repo_slug}/deploy-keys
export def "repositories-deploy-keys list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, key: string, repository: record, comment: string, label: string, added_on: string, last_used: string, links: record, owner: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deploy-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a repository deploy key
#
# POST /repositories/{workspace}/{repo_slug}/deploy-keys
export def "repositories-deploy-keys post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, key: string, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, comment: string, label: string, added_on: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deploy-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a repository deploy key
#
# DELETE /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
export def "repositories-deploy-keys delete" [
  key_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deploy-keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a repository deploy key
#
# GET /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
export def "repositories-deploy-keys get" [
  key_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, key: string, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, comment: string, label: string, added_on: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deploy-keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a repository deploy key
#
# PUT /repositories/{workspace}/{repo_slug}/deploy-keys/{key_id}
export def "repositories-deploy-keys put" [
  key_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, key: string, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, comment: string, label: string, added_on: string, last_used: string, links: record<self: record<href: string, name: string>>, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deploy-keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List deployments
#
# GET /repositories/{workspace}/{repo_slug}/deployments
# operationId: getDeploymentsForRepository
export def "repositories-deployments list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, state: record, environment: record, release: record>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deployments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a deployment
#
# GET /repositories/{workspace}/{repo_slug}/deployments/{deployment_uuid}
# operationId: getDeploymentForRepository
export def "repositories-deployments get" [
  workspace: string
  repo_slug: string
  deployment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, state: record<type: string>, environment: record<type: string, uuid: string, name: string>, release: record<type: string, uuid: string, name: string, url: string, commit: record<repository: record, participants: list>, created_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deployments/($deployment_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List variables for an environment
#
# GET /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables
# operationId: getDeploymentVariables
export def "repositories-deployments-config-environments-variables get" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, key: string, value: string, secured: bool>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deployments_config/environments/($environment_uuid)/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a variable for an environment
#
# POST /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables
# operationId: createDeploymentVariable
export def "repositories-deployments-config-environments-variables createDeploymentVariable" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deployments_config/environments/($environment_uuid)/variables")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a variable for an environment
#
# PUT /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}
# operationId: updateDeploymentVariable
export def "repositories-deployments-config-environments-variables updateDeploymentVariable" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deployments_config/environments/($environment_uuid)/variables/($variable_uuid)")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a variable for an environment
#
# DELETE /repositories/{workspace}/{repo_slug}/deployments_config/environments/{environment_uuid}/variables/{variable_uuid}
# operationId: deleteDeploymentVariable
export def "repositories-deployments-config-environments-variables delete" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/deployments_config/environments/($environment_uuid)/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Compare two commits
#
# GET /repositories/{workspace}/{repo_slug}/diff/{spec}
export def "repositories-diff get" [
  repo_slug: string
  spec: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --context: int # Generate diffs with <n> lines of context instead of the usual three.
  --path: string # Limit the diff to a particular file (this parameter can be repeated for multiple paths).
  --ignore-whitespace: oneof<nothing, bool> # Generate diffs that ignore whitespace.
  --binary: oneof<nothing, bool> # Generate diffs that include binary files, true if omitted.
  --renames: oneof<nothing, bool> # Whether to perform rename detection, true if omitted.
  --merge: oneof<nothing, bool> # This parameter is deprecated. The 'topic' parameter should be used instead. The 'merge' and 'topic' parameters cannot be both used at the same time.  If true, the source commit is merged into the destination commit, and then a diff from the destination to the merge result is returned. If false, a simple 'two dot' diff between the source and destination is returned. True if omitted.
  --topic: oneof<nothing, bool> # If true, returns 2-way 'three-dot' diff. This is a diff between the source commit and the merge base of the source commit and the destination commit. If false, a simple 'two dot' diff between the source and destination is returned.  If omitted, defaults to true, ie. a 2 way 'three-dot' diff is returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "context" $context "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "ignore_whitespace" $ignore_whitespace "scalar") (serialize-qp "binary" $binary "scalar") (serialize-qp "renames" $renames "scalar") (serialize-qp "merge" $merge "scalar") (serialize-qp "topic" $topic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/diff/($spec)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Compare two commit diff stats
#
# GET /repositories/{workspace}/{repo_slug}/diffstat/{spec}
export def "repositories-diffstat get" [
  repo_slug: string
  spec: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignore-whitespace: oneof<nothing, bool> # Generate diffs that ignore whitespace
  --merge: oneof<nothing, bool> # This parameter is deprecated. The 'topic' parameter should be used instead. The 'merge' and 'topic' parameters cannot be both used at the same time.  If true, the source commit is merged into the destination commit, and then a diffstat from the destination to the merge result is returned. If false, a simple 'two dot' diffstat between the source and destination is returned. True if omitted.
  --path: string # Limit the diffstat to a particular file (this parameter can be repeated for multiple paths).
  --renames: oneof<nothing, bool> # Whether to perform rename detection, true if omitted.
  --topic: oneof<nothing, bool> # If true, returns 2-way 'three-dot' diff. This is a diff between the source commit and the merge base of the source commit and the destination commit. If false, a simple 'two dot' diff between the source and destination is returned.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, status: string, lines_added: int, lines_removed: int, old: record, new: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_whitespace" $ignore_whitespace "scalar") (serialize-qp "merge" $merge "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "renames" $renames "scalar") (serialize-qp "topic" $topic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/diffstat/($spec)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List download artifacts
#
# GET /repositories/{workspace}/{repo_slug}/downloads
export def "repositories-downloads list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/downloads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a download artifact
#
# POST /repositories/{workspace}/{repo_slug}/downloads
export def "repositories-downloads post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/downloads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a download artifact
#
# DELETE /repositories/{workspace}/{repo_slug}/downloads/{filename}
export def "repositories-downloads delete" [
  filename: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/downloads/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a download artifact link
#
# GET /repositories/{workspace}/{repo_slug}/downloads/{filename}
export def "repositories-downloads get" [
  filename: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/downloads/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the effective, or currently applied, branching model for a repository
#
# GET /repositories/{workspace}/{repo_slug}/effective-branching-model
export def "repositories-effective-branching-model get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, branch_types: table<kind: string, prefix: string>, development: record<branch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>, name: string, use_mainbranch: bool>, production: record<branch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>, name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/effective-branching-model")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List effective default reviewers
#
# GET /repositories/{workspace}/{repo_slug}/effective-default-reviewers
export def "repositories-effective-default-reviewers get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, reviewer_type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/effective-default-reviewers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List environments
#
# GET /repositories/{workspace}/{repo_slug}/environments
# operationId: getEnvironmentsForRepository
export def "repositories-environments list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, name: string>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an environment
#
# POST /repositories/{workspace}/{repo_slug}/environments
# operationId: createEnvironment
export def "repositories-environments createEnvironment" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the environment.
  --name: string # The name of the environment.
]: any -> record<type: string, uuid: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/environments")
  let body = {type: $type, uuid: $uuid, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an environment
#
# GET /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}
# operationId: getEnvironmentForRepository
export def "repositories-environments get" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/environments/($environment_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an environment
#
# DELETE /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}
# operationId: deleteEnvironmentForRepository
export def "repositories-environments delete" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/environments/($environment_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an environment
#
# POST /repositories/{workspace}/{repo_slug}/environments/{environment_uuid}/changes
# operationId: updateEnvironmentForRepository
export def "repositories-environments-changes updateEnvironmentForRepository" [
  workspace: string
  repo_slug: string
  environment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/environments/($environment_uuid)/changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file conflicts for a commit spec
#
# GET /repositories/{workspace}/{repo_slug}/file-conflicts/{spec}
export def "repositories-file-conflicts get" [
  repo_slug: string
  spec: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, path: string, scenario: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/file-conflicts/($spec)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commits that modified a file
#
# GET /repositories/{workspace}/{repo_slug}/filehistory/{commit}/{path}
export def "repositories-filehistory get" [
  commit: string
  path: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --renames: string #  When `true`, Bitbucket will follow the history of the file across renames (this is the default behavior). This can be turned off by specifying `false`.
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, path: string, commit: record, attributes: string, escaped_path: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "renames" $renames "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/filehistory/($commit)/($path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repository forks
#
# GET /repositories/{workspace}/{repo_slug}/forks
export def "repositories-forks get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer # Filters the result based on the authenticated user's role on each repository.  * **member**: returns repositories to which the user has explicit read access * **contributor**: returns repositories to which the user has explicit write access * **admin**: returns repositories to which the user has explicit administrator access * **owner**: returns all repositories owned by the current user
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/forks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fork a repository
#
# POST /repositories/{workspace}/{repo_slug}/forks
# --links shape: {self?: record, html?: record, avatar?: record, pullrequests?: record, commits?: record, forks?: record, watchers?: record, downloads?: record, clone?: list, hooks?: record}
export def "repositories-forks post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record, avatar?: record, pullrequests?: record, commits?: record, forks?: record, watchers?: record, downloads?: record, clone?: list, hooks?: record}
  --uuid: string # The repository's immutable id. This can be used as a substitute for the slug segment in URLs. Doing this guarantees your URLs will survive renaming of the repository by its owner, or even transfer of the repository to a different user.
  --full-name: string # The concatenation of the repository owner's username and the slugified name, e.g. "evzijst/interruptingcow". This is the same string used in Bitbucket URLs.
  --is-private: oneof<nothing, bool>
  --parent: any
  --scm: string@scm-completer
  --owner: any
  --name: string
  --description: string
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --size: int
  --language: string
  --has-issues: oneof<nothing, bool> #  The issue tracker for this repository is enabled. Issue Tracker features are not supported for repositories in workspaces administered through admin.atlassian.com.
  --has-wiki: oneof<nothing, bool> #  The wiki for this repository is enabled. Wiki features are not supported for repositories in workspaces administered through admin.atlassian.com.
  --fork-policy: string@fork-policy-completer #  Controls the rules for forking this repository.  * **allow_forks**: unrestricted forking * **no_public_forks**: restrict forking to private forks (forks cannot   be made public later) * **no_forks**: deny all forking
  --project: any
  --mainbranch: any
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, avatar: record<href: string, name: string>, pullrequests: record<href: string, name: string>, commits: record<href: string, name: string>, forks: record<href: string, name: string>, watchers: record<href: string, name: string>, downloads: record<href: string, name: string>, clone: list<record>, hooks: record<href: string, name: string>>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record<self: record, commits: record, html: record>, name: string, target: record<repository: any, participants: list>, merge_strategies: list<string>, default_merge_strategy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/forks")
  let body = {type: $type, links: $links, uuid: $uuid, full_name: $full_name, is_private: $is_private, parent: $parent, scm: $scm, owner: $owner, name: $name, description: $description, created_on: $created_on, updated_on: $updated_on, size: $size, language: $language, has_issues: $has_issues, has_wiki: $has_wiki, fork_policy: $fork_policy, project: $project, mainbranch: $mainbranch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List webhooks for a repository
#
# GET /repositories/{workspace}/{repo_slug}/hooks
export def "repositories-hooks list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record, active: bool, created_at: string, events: list, secret_set: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook for a repository
#
# POST /repositories/{workspace}/{repo_slug}/hooks
export def "repositories-hooks post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record<type: string>, active: bool, created_at: string, events: list<string>, secret_set: bool, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a webhook for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/hooks/{uid}
export def "repositories-hooks delete" [
  repo_slug: string
  uid: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/hooks/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook for a repository
#
# GET /repositories/{workspace}/{repo_slug}/hooks/{uid}
export def "repositories-hooks get" [
  repo_slug: string
  uid: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record<type: string>, active: bool, created_at: string, events: list<string>, secret_set: bool, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/hooks/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/hooks/{uid}
export def "repositories-hooks put" [
  repo_slug: string
  uid: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record<type: string>, active: bool, created_at: string, events: list<string>, secret_set: bool, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/hooks/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List issues
#
# GET /repositories/{workspace}/{repo_slug}/issues
# DEPRECATED
@deprecated
export def "repositories-issues list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, id: int, repository: record, title: string, reporter: record, assignee: record, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record, version: record, component: record, votes: int, content: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues
# DEPRECATED
# --links shape: {self?: record, html?: record, comments?: record, attachments?: record, watch?: record, vote?: record}
# --content shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
@deprecated
export def "repositories-issues post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record, comments?: record, attachments?: record, watch?: record, vote?: record}
  --id: int
  --repository: any
  --title: string
  --reporter: any
  --assignee: any
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --edited-on: string # format: date-time
  --state: string@state-completer-1
  --kind: string@kind-completer-1
  --priority: string@priority-completer
  --milestone: any
  --version: any
  --component: any
  --votes: int
  --content: record # shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, comments: record<href: string, name: string>, attachments: record<href: string, name: string>, watch: record<href: string, name: string>, vote: record<href: string, name: string>>, id: int, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, title: string, reporter: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, assignee: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record<type: string, links: record<self: record>, name: string, id: int>, version: record<type: string, links: record<self: record>, name: string, id: int>, component: record<type: string, links: record<self: record>, name: string, id: int>, votes: int, content: record<raw: string, markup: string, html: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues")
  let body = {type: $type, links: $links, id: $id, repository: $repository, title: $title, reporter: $reporter, assignee: $assignee, created_on: $created_on, updated_on: $updated_on, edited_on: $edited_on, state: $state, kind: $kind, priority: $priority, milestone: $milestone, version: $version, component: $component, votes: $votes, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export issues
#
# POST /repositories/{workspace}/{repo_slug}/issues/export
# DEPRECATED
@deprecated
export def "repositories-issues-export post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --project-key: string
  --project-name: string
  --send-email: oneof<nothing, bool>
  --include-attachments: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/export")
  let body = {type: $type, project_key: $project_key, project_name: $project_name, send_email: $send_email, include_attachments: $include_attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check issue export status
#
# GET /repositories/{workspace}/{repo_slug}/issues/export/{repo_name}-issues-{task_id}.zip
# DEPRECATED
@deprecated
export def "repositories-issues-export get" [
  repo_name: string
  repo_slug: string
  task_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: string, phase: string, total: int, count: int, pct: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/export/($repo_name)-issues-($task_id).zip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check issue import status
#
# GET /repositories/{workspace}/{repo_slug}/issues/import
# DEPRECATED
@deprecated
export def "repositories-issues-import get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: string, phase: string, total: int, count: int, pct: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/import")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import issues
#
# POST /repositories/{workspace}/{repo_slug}/issues/import
# DEPRECATED
@deprecated
export def "repositories-issues-import post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, status: string, phase: string, total: int, count: int, pct: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/import")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}
# DEPRECATED
@deprecated
export def "repositories-issues delete" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}
# DEPRECATED
@deprecated
export def "repositories-issues get" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, comments: record<href: string, name: string>, attachments: record<href: string, name: string>, watch: record<href: string, name: string>, vote: record<href: string, name: string>>, id: int, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, title: string, reporter: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, assignee: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record<type: string, links: record<self: record>, name: string, id: int>, version: record<type: string, links: record<self: record>, name: string, id: int>, component: record<type: string, links: record<self: record>, name: string, id: int>, votes: int, content: record<raw: string, markup: string, html: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}
# DEPRECATED
@deprecated
export def "repositories-issues put" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, comments: record<href: string, name: string>, attachments: record<href: string, name: string>, watch: record<href: string, name: string>, vote: record<href: string, name: string>>, id: int, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, title: string, reporter: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, assignee: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record<type: string, links: record<self: record>, name: string, id: int>, version: record<type: string, links: record<self: record>, name: string, id: int>, component: record<type: string, links: record<self: record>, name: string, id: int>, votes: int, content: record<raw: string, markup: string, html: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List attachments for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments
# DEPRECATED
@deprecated
export def "repositories-issues-attachments list" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload an attachment to an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments
# DEPRECATED
@deprecated
export def "repositories-issues-attachments post" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an attachment for an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}
# DEPRECATED
@deprecated
export def "repositories-issues-attachments delete" [
  issue_id: string
  path: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/attachments/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get attachment for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/attachments/{path}
# DEPRECATED
@deprecated
export def "repositories-issues-attachments get" [
  issue_id: string
  path: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/attachments/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List changes on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes
# DEPRECATED
@deprecated
export def "repositories-issues-changes list" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --qp-sort: string #  Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string, created_on: string, user: record, issue: record, changes: record, message: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify the state of an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes
# DEPRECATED
# --links shape: {self?: record, issue?: record}
# --changes shape: {assignee?: record, state?: record, title?: record, kind?: record, milestone?: record, component?: record, priority?: record, version?: record, content?: record}
# --message shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
@deprecated
export def "repositories-issues-changes post" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, issue?: record}
  --name: string
  --created-on: string # format: date-time
  --user: any
  --issue: any
  --changes: record # shape: {assignee?: record, state?: record, title?: record, kind?: record, milestone?: record, component?: record, priority?: record, version?: record, content?: record}
  --message: record # shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
]: any -> record<type: string, links: record<self: record<href: string, name: string>, issue: record<href: string, name: string>>, name: string, created_on: string, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, issue: record<type: string, links: record<self: record, html: record, comments: record, attachments: record, watch: record, vote: record>, id: int, repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, title: string, reporter: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, assignee: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record<type: string, links: record, name: string, id: int>, version: record<type: string, links: record, name: string, id: int>, component: record<type: string, links: record, name: string, id: int>, votes: int, content: record<raw: string, markup: string, html: string>>, changes: record<assignee: record<old: string, new: string>, state: record<old: string, new: string>, title: record<old: string, new: string>, kind: record<old: string, new: string>, milestone: record<old: string, new: string>, component: record<old: string, new: string>, priority: record<old: string, new: string>, version: record<old: string, new: string>, content: record<old: string, new: string>>, message: record<raw: string, markup: string, html: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/changes")
  let body = {type: $type, links: $links, name: $name, created_on: $created_on, user: $user, issue: $issue, changes: $changes, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get issue change object
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/changes/{change_id}
# DEPRECATED
@deprecated
export def "repositories-issues-changes get" [
  change_id: string
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, issue: record<href: string, name: string>>, name: string, created_on: string, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, issue: record<type: string, links: record<self: record, html: record, comments: record, attachments: record, watch: record, vote: record>, id: int, repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, title: string, reporter: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, assignee: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record<type: string, links: record, name: string, id: int>, version: record<type: string, links: record, name: string, id: int>, component: record<type: string, links: record, name: string, id: int>, votes: int, content: record<raw: string, markup: string, html: string>>, changes: record<assignee: record<old: string, new: string>, state: record<old: string, new: string>, title: record<old: string, new: string>, kind: record<old: string, new: string>, milestone: record<old: string, new: string>, component: record<old: string, new: string>, priority: record<old: string, new: string>, version: record<old: string, new: string>, content: record<old: string, new: string>>, message: record<raw: string, markup: string, html: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/changes/($change_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List comments on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments
# DEPRECATED
@deprecated
export def "repositories-issues-comments list" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<issue: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a comment on an issue
#
# POST /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments
# DEPRECATED
@deprecated
export def "repositories-issues-comments post" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issue: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/comments")
  let body = {issue: $issue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a comment on an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
# DEPRECATED
@deprecated
export def "repositories-issues-comments delete" [
  comment_id: int
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a comment on an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
# DEPRECATED
@deprecated
export def "repositories-issues-comments get" [
  comment_id: int
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<issue: record<type: string, links: record<self: record, html: record, comments: record, attachments: record, watch: record, vote: record>, id: int, repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, title: string, reporter: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, assignee: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record<type: string, links: record, name: string, id: int>, version: record<type: string, links: record, name: string, id: int>, component: record<type: string, links: record, name: string, id: int>, votes: int, content: record<raw: string, markup: string, html: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a comment on an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/comments/{comment_id}
# DEPRECATED
@deprecated
export def "repositories-issues-comments put" [
  comment_id: int
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --issue: any
]: any -> record<issue: record<type: string, links: record<self: record, html: record, comments: record, attachments: record, watch: record, vote: record>, id: int, repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, title: string, reporter: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, assignee: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, created_on: string, updated_on: string, edited_on: string, state: string, kind: string, priority: string, milestone: record<type: string, links: record, name: string, id: int>, version: record<type: string, links: record, name: string, id: int>, component: record<type: string, links: record, name: string, id: int>, votes: int, content: record<raw: string, markup: string, html: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/comments/($comment_id)")
  let body = {issue: $issue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove vote for an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
# DEPRECATED
@deprecated
export def "repositories-issues-vote delete" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, error: record<message: string, detail: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/vote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if current user voted for an issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
# DEPRECATED
@deprecated
export def "repositories-issues-vote get" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/vote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Vote for an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/vote
# DEPRECATED
@deprecated
export def "repositories-issues-vote put" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/vote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop watching an issue
#
# DELETE /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
# DEPRECATED
@deprecated
export def "repositories-issues-watch delete" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if current user is watching a issue
#
# GET /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
# DEPRECATED
@deprecated
export def "repositories-issues-watch get" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Watch an issue
#
# PUT /repositories/{workspace}/{repo_slug}/issues/{issue_id}/watch
# DEPRECATED
@deprecated
export def "repositories-issues-watch put" [
  issue_id: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/issues/($issue_id)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the common ancestor between two commits
#
# GET /repositories/{workspace}/{repo_slug}/merge-base/{revspec}
export def "repositories-merge-base get" [
  repo_slug: string
  revspec: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: any, merge_strategies: list, default_merge_strategy: string>>, participants: table<type: string, user: record, role: string, approved: bool, state: string, participated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/merge-base/($revspec)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List milestones
#
# GET /repositories/{workspace}/{repo_slug}/milestones
# DEPRECATED
@deprecated
export def "repositories-milestones list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/milestones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a milestone
#
# GET /repositories/{workspace}/{repo_slug}/milestones/{milestone_id}
# DEPRECATED
@deprecated
export def "repositories-milestones get" [
  milestone_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, name: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/milestones/($milestone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the inheritance state for repository settings
#
# GET /repositories/{workspace}/{repo_slug}/override-settings
export def "repositories-override-settings get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, override_settings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/override-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the inheritance state for repository settings                 
#
# PUT /repositories/{workspace}/{repo_slug}/override-settings
export def "repositories-override-settings put" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/override-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a patch for two commits
#
# GET /repositories/{workspace}/{repo_slug}/patch/{spec}
export def "repositories-patch get" [
  repo_slug: string
  spec: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/patch/($spec)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List explicit group permissions for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/groups
export def "repositories-permissions-config-groups list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, permission: string, group: record, repository: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an explicit group permission for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
export def "repositories-permissions-config-groups delete" [
  group_slug: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/groups/($group_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an explicit group permission for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
export def "repositories-permissions-config-groups get" [
  group_slug: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, permission: string, group: record<type: string, links: record<self: record, html: record>, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, workspace: record<type: string, links: record, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string>, name: string, slug: string, full_slug: string>, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/groups/($group_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an explicit group permission for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/permissions-config/groups/{group_slug}
export def "repositories-permissions-config-groups put" [
  group_slug: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permission: string@permission-completer
]: any -> record<type: string, links: record<self: record<href: string, name: string>>, permission: string, group: record<type: string, links: record<self: record, html: record>, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, workspace: record<type: string, links: record, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string>, name: string, slug: string, full_slug: string>, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/groups/($group_slug)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List explicit user permissions for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/users
export def "repositories-permissions-config-users list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, permission: string, user: record, repository: record, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an explicit user permission for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
export def "repositories-permissions-config-users delete" [
  repo_slug: string
  selected_user_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/users/($selected_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an explicit user permission for a repository
#
# GET /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
export def "repositories-permissions-config-users get" [
  repo_slug: string
  selected_user_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, permission: string, user: record<links: record<avatar: record, self: record, html: record, repositories: record>, account_id: string, account_status: string, has_2fa_enabled: bool, nickname: string, is_staff: bool>, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, links: record<self: record<href: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/users/($selected_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an explicit user permission for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/permissions-config/users/{selected_user_id}
export def "repositories-permissions-config-users put" [
  repo_slug: string
  selected_user_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permission: string@permission-completer
]: any -> record<type: string, permission: string, user: record<links: record<avatar: record, self: record, html: record, repositories: record>, account_id: string, account_status: string, has_2fa_enabled: bool, nickname: string, is_staff: bool>, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, links: record<self: record<href: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/permissions-config/users/($selected_user_id)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List pipelines
#
# GET /repositories/{workspace}/{repo_slug}/pipelines
# operationId: getPipelinesForRepository
export def "repositories-pipelines list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creatoruuid: string # The UUID of the creator of the pipeline to filter by. (format: uuid)
  --targetref-type: string@targetref-type-completer # The type of the reference to filter by.
  --targetref-name: string # The reference name to filter by.
  --targetbranch: string # The name of the branch to filter by.
  --targetcommithash: string # The revision to filter by.
  --targetselectorpattern: string # The pipeline pattern to filter by.
  --targetselectortype: string@targetselectortype-completer # The type of pipeline to filter by.
  --created-on: string # The creation date to filter by. (format: date-time)
  --trigger-type: string@trigger-type-completer # The trigger type to filter by.
  --status: string@status-completer # The pipeline status to filter by.
  --qp-sort: string@sort-completer # The attribute name to sort on.
  --page: int # The page number of elements to retrieve. (format: int32, default: 1)
  --pagelen: int # The maximum number of results to return. (format: int32, default: 10)
]: nothing -> record<page: int, values: table<type: string, uuid: string, build_number: int, creator: record, repository: record, target: record, trigger: record, state: record, variables: list, created_on: string, completed_on: string, build_seconds_used: int, configuration_sources: list, links: record>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creator.uuid" $creatoruuid "scalar") (serialize-qp "target.ref_type" $targetref_type "scalar") (serialize-qp "target.ref_name" $targetref_name "scalar") (serialize-qp "target.branch" $targetbranch "scalar") (serialize-qp "target.commit.hash" $targetcommithash "scalar") (serialize-qp "target.selector.pattern" $targetselectorpattern "scalar") (serialize-qp "target.selector.type" $targetselectortype "scalar") (serialize-qp "created_on" $created_on "scalar") (serialize-qp "trigger_type" $trigger_type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run a pipeline
#
# POST /repositories/{workspace}/{repo_slug}/pipelines
# operationId: createPipelineForRepository
# --variables item shape: {type: string, uuid?: string, key?: string, value?: string, secured?: bool}
# --configuration_sources item shape: {source: string, uri: string}
export def "repositories-pipelines createPipelineForRepository" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the pipeline.
  --build-number: int # The build number of the pipeline.
  --creator: any
  --repository: any
  --target: any
  --trigger: any
  --state: any
  --body-variables: list # The variables for the pipeline. — item shape: {type: string, uuid?: string, key?: string, value?: string, secured?: bool}
  --created-on: string # The timestamp when the pipeline was created. (format: date-time)
  --completed-on: string # The timestamp when the Pipeline was completed. This is not set if the pipeline is still in progress. (format: date-time)
  --build-seconds-used: int # The number of build seconds used by this pipeline.
  --configuration-sources: list # An ordered list of sources of the pipeline configuration — item shape: {source: string, uri: string}
  --links: any
]: any -> record<type: string, uuid: string, build_number: int, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, target: record<type: string>, trigger: record<type: string>, state: record<type: string>, variables: table<type: string, uuid: string, key: string, value: string, secured: bool>, created_on: string, completed_on: string, build_seconds_used: int, configuration_sources: table<source: string, uri: string>, links: record<type: string, self: record<type: string, href: string>, steps: record<type: string, href: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines")
  let body = {type: $type, uuid: $uuid, build_number: $build_number, creator: $creator, repository: $repository, target: $target, trigger: $trigger, state: $state, variables: $body_variables, created_on: $created_on, completed_on: $completed_on, build_seconds_used: $build_seconds_used, configuration_sources: $configuration_sources, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List caches
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/caches
# operationId: getRepositoryPipelineCaches
export def "repositories-pipelines-config-caches get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, pipeline_uuid: string, step_uuid: string, name: string, key_hash: string, path: string, file_size_bytes: int, created_on: string>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/caches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete caches
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines-config/caches
# operationId: deleteRepositoryPipelineCaches
export def "repositories-pipelines-config-caches delete-by-workspace-repo_slug" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The cache name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/caches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a cache
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}
# operationId: deleteRepositoryPipelineCache
export def "repositories-pipelines-config-caches delete-by-workspace-repo_slug-cache_uuid" [
  workspace: string
  repo_slug: string
  cache_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/caches/($cache_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cache content URI
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/caches/{cache_uuid}/content-uri
# operationId: getRepositoryPipelineCacheContentURI
export def "repositories-pipelines-config-caches-content-uri get" [
  workspace: string
  repo_slug: string
  cache_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/caches/($cache_uuid)/content-uri")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get repository runners
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/runners
# operationId: getRepositoryRunners
export def "repositories-pipelines-config-runners list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, name: string, labels: list, state: record, created_on: string, updated_on: string, oauth_client: record>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/runners")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create repository runner
#
# POST /repositories/{workspace}/{repo_slug}/pipelines-config/runners
# operationId: createRepositoryRunner
export def "repositories-pipelines-config-runners createRepositoryRunner" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, name: string, labels: list<string>, state: record<type: string, status: string, version: record<type: string, version: string, current: string>, updated_on: string, cordoned: bool>, created_on: string, updated_on: string, oauth_client: record<type: string, id: string, secret: string, token_endpoint: string, audience: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/runners")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get repository runner
#
# GET /repositories/{workspace}/{repo_slug}/pipelines-config/runners/{runner_uuid}
# operationId: getRepositoryRunner
export def "repositories-pipelines-config-runners get" [
  workspace: string
  repo_slug: string
  runner_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, name: string, labels: list<string>, state: record<type: string, status: string, version: record<type: string, version: string, current: string>, updated_on: string, cordoned: bool>, created_on: string, updated_on: string, oauth_client: record<type: string, id: string, secret: string, token_endpoint: string, audience: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/runners/($runner_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update repository runner
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines-config/runners/{runner_uuid}
# operationId: updateRepositoryRunner
export def "repositories-pipelines-config-runners updateRepositoryRunner" [
  workspace: string
  repo_slug: string
  runner_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, name: string, labels: list<string>, state: record<type: string, status: string, version: record<type: string, version: string, current: string>, updated_on: string, cordoned: bool>, created_on: string, updated_on: string, oauth_client: record<type: string, id: string, secret: string, token_endpoint: string, audience: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/runners/($runner_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete repository runner
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines-config/runners/{runner_uuid}
# operationId: deleteRepositoryRunner
export def "repositories-pipelines-config-runners delete" [
  workspace: string
  repo_slug: string
  runner_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines-config/runners/($runner_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}
# operationId: getPipelineForRepository
export def "repositories-pipelines get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, build_number: int, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>, target: record<type: string>, trigger: record<type: string>, state: record<type: string>, variables: table<type: string, uuid: string, key: string, value: string, secured: bool>, created_on: string, completed_on: string, build_seconds_used: int, configuration_sources: table<source: string, uri: string>, links: record<type: string, self: record<type: string, href: string>, steps: record<type: string, href: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List steps for a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps
# operationId: getPipelineStepsForRepository
export def "repositories-pipelines-steps list" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, started_on: string, completed_on: string, state: record, image: record, setup_commands: list, script_commands: list>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/steps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a step of a pipeline
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}
# operationId: getPipelineStepForRepository
export def "repositories-pipelines-steps get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, started_on: string, completed_on: string, state: record<type: string>, image: record<name: string, username: string, password: string, email: string>, setup_commands: table<name: string, command: string>, script_commands: table<name: string, command: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/steps/($step_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get log file for a step
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/log
# operationId: getPipelineStepLogForRepository
export def "repositories-pipelines-steps-log get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/steps/($step_uuid)/log")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the logs for the build container or a service container for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/logs/{log_uuid}
# operationId: getPipelineContainerLog
export def "repositories-pipelines-steps-logs get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  log_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/steps/($step_uuid)/logs/($log_uuid)")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a summary of test reports for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports
# operationId: getPipelineTestReports
export def "repositories-pipelines-steps-test-reports get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/steps/($step_uuid)/test_reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get test cases for a given step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases
# operationId: getPipelineTestReportTestCases
export def "repositories-pipelines-steps-test-reports-test-cases get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/steps/($step_uuid)/test_reports/test_cases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get test case reasons (output) for a given test case in a step of a pipeline.
#
# GET /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/steps/{step_uuid}/test_reports/test_cases/{test_case_uuid}/test_case_reasons
# operationId: getPipelineTestReportTestCaseReasons
export def "repositories-pipelines-steps-test-reports-test-cases-test-case-reasons get" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  step_uuid: string
  test_case_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/steps/($step_uuid)/test_reports/test_cases/($test_case_uuid)/test_case_reasons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a pipeline
#
# POST /repositories/{workspace}/{repo_slug}/pipelines/{pipeline_uuid}/stopPipeline
# operationId: stopPipeline
export def "repositories-pipelines-stop-pipeline stopPipeline" [
  workspace: string
  repo_slug: string
  pipeline_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines/($pipeline_uuid)/stopPipeline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get configuration
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config
# operationId: getRepositoryPipelineConfig
export def "repositories-pipelines-config get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, enabled: bool, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update configuration
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config
# operationId: updateRepositoryPipelineConfig
export def "repositories-pipelines-config updateRepositoryPipelineConfig" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --enabled: oneof<nothing, bool> # Whether Pipelines is enabled for the repository.
  --repository: any
]: any -> record<type: string, enabled: bool, repository: record<type: string, links: record<self: record, html: record, avatar: record, pullrequests: record, commits: record, forks: record, watchers: record, downloads: record, clone: list, hooks: record>, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, mainbranch: record<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config")
  let body = {type: $type, enabled: $enabled, repository: $repository} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the next build number
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/build_number
# operationId: updateRepositoryBuildNumber
export def "repositories-pipelines-config-build-number updateRepositoryBuildNumber" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --next: int # The next number that will be used as build number.
]: any -> record<type: string, next: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/build_number")
  let body = {type: $type, next: $next} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a schedule
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/schedules
# operationId: createRepositoryPipelineSchedule
# --target shape: {selector: any, ref_name: string, ref_type: "branch"}
export def "repositories-pipelines-config-schedules createRepositoryPipelineSchedule" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  target: record # The target on which the schedule will be executed. — shape: {selector: any, ref_name: string, ref_type: "branch"}
  --enabled: oneof<nothing, bool> # Whether the schedule is enabled.
  cron_pattern: string # The cron expression with second precision (7 fields) that the schedule applies. For example, for expression: 0 0 12 * * ? *, will execute at 12pm UTC every day.
]: any -> record<type: string, uuid: string, enabled: bool, target: record<ref_type: string, ref_name: string, commit: record<repository: record, participants: list>, selector: record<type: string, pattern: string>>, cron_pattern: string, created_on: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/schedules")
  let body = {type: $type, target: $target, enabled: $enabled, cron_pattern: $cron_pattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List schedules
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules
# operationId: getRepositoryPipelineSchedules
export def "repositories-pipelines-config-schedules list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, enabled: bool, target: record, cron_pattern: string, created_on: string, updated_on: string>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/schedules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a schedule
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# operationId: getRepositoryPipelineSchedule
export def "repositories-pipelines-config-schedules get" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, enabled: bool, target: record<ref_type: string, ref_name: string, commit: record<repository: record, participants: list>, selector: record<type: string, pattern: string>>, cron_pattern: string, created_on: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/schedules/($schedule_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a schedule
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# operationId: updateRepositoryPipelineSchedule
export def "repositories-pipelines-config-schedules updateRepositoryPipelineSchedule" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --enabled: oneof<nothing, bool> # Whether the schedule is enabled.
]: any -> record<type: string, uuid: string, enabled: bool, target: record<ref_type: string, ref_name: string, commit: record<repository: record, participants: list>, selector: record<type: string, pattern: string>>, cron_pattern: string, created_on: string, updated_on: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/schedules/($schedule_uuid)")
  let body = {type: $type, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a schedule
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}
# operationId: deleteRepositoryPipelineSchedule
export def "repositories-pipelines-config-schedules delete" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/schedules/($schedule_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List executions of a schedule
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/schedules/{schedule_uuid}/executions
# operationId: getRepositoryPipelineScheduleExecutions
export def "repositories-pipelines-config-schedules-executions get" [
  workspace: string
  repo_slug: string
  schedule_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/schedules/($schedule_uuid)/executions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SSH key pair
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# operationId: getRepositoryPipelineSshKeyPair
export def "repositories-pipelines-config-ssh-key-pair get" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, private_key: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/key_pair")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SSH key pair
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# operationId: updateRepositoryPipelineKeyPair
export def "repositories-pipelines-config-ssh-key-pair updateRepositoryPipelineKeyPair" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --private-key: string # The SSH private key. This value will be empty when retrieving the SSH key pair.
  --public-key: string # The SSH public key.
]: any -> record<type: string, private_key: string, public_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/key_pair")
  let body = {type: $type, private_key: $private_key, public_key: $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete SSH key pair
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/key_pair
# operationId: deleteRepositoryPipelineKeyPair
export def "repositories-pipelines-config-ssh-key-pair delete" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/key_pair")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List known hosts
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts
# operationId: getRepositoryPipelineKnownHosts
export def "repositories-pipelines-config-ssh-known-hosts list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, hostname: string, public_key: record>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/known_hosts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a known host
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts
# operationId: createRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts createRepositoryPipelineKnownHost" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the known host.
  --hostname: string # The hostname of the known host.
  --public-key: any
]: any -> record<type: string, uuid: string, hostname: string, public_key: record<type: string, key_type: string, key: string, md5_fingerprint: string, sha256_fingerprint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/known_hosts")
  let body = {type: $type, uuid: $uuid, hostname: $hostname, public_key: $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a known host
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# operationId: getRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts get" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, hostname: string, public_key: record<type: string, key_type: string, key: string, md5_fingerprint: string, sha256_fingerprint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/known_hosts/($known_host_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a known host
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# operationId: updateRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts updateRepositoryPipelineKnownHost" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the known host.
  --hostname: string # The hostname of the known host.
  --public-key: any
]: any -> record<type: string, uuid: string, hostname: string, public_key: record<type: string, key_type: string, key: string, md5_fingerprint: string, sha256_fingerprint: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/known_hosts/($known_host_uuid)")
  let body = {type: $type, uuid: $uuid, hostname: $hostname, public_key: $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a known host
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/ssh/known_hosts/{known_host_uuid}
# operationId: deleteRepositoryPipelineKnownHost
export def "repositories-pipelines-config-ssh-known-hosts delete" [
  workspace: string
  repo_slug: string
  known_host_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/ssh/known_hosts/($known_host_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List variables for a repository
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/variables
# operationId: getRepositoryPipelineVariables
export def "repositories-pipelines-config-variables list" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, key: string, value: string, secured: bool>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a variable for a repository
#
# POST /repositories/{workspace}/{repo_slug}/pipelines_config/variables
# operationId: createRepositoryPipelineVariable
export def "repositories-pipelines-config-variables createRepositoryPipelineVariable" [
  workspace: string
  repo_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/variables")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a variable for a repository
#
# GET /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# operationId: getRepositoryPipelineVariable
export def "repositories-pipelines-config-variables get" [
  workspace: string
  repo_slug: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a variable for a repository
#
# PUT /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# operationId: updateRepositoryPipelineVariable
export def "repositories-pipelines-config-variables updateRepositoryPipelineVariable" [
  workspace: string
  repo_slug: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/variables/($variable_uuid)")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a variable for a repository
#
# DELETE /repositories/{workspace}/{repo_slug}/pipelines_config/variables/{variable_uuid}
# operationId: deleteRepositoryPipelineVariable
export def "repositories-pipelines-config-variables delete" [
  workspace: string
  repo_slug: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pipelines_config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a repository application property
#
# PUT /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: updateRepositoryHostedPropertyValue
export def "repositories-properties updateRepositoryHostedPropertyValue" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/properties/($app_key)/($property_name)")
  let body = {_attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a repository application property
#
# DELETE /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: deleteRepositoryHostedPropertyValue
export def "repositories-properties delete" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a repository application property
#
# GET /repositories/{workspace}/{repo_slug}/properties/{app_key}/{property_name}
# operationId: getRepositoryHostedPropertyValue
export def "repositories-properties get" [
  workspace: string
  repo_slug: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pull requests
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests
export def "repositories-pullrequests list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer-2 # Only return pull requests that are in this state. This parameter can be repeated.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, id: int, title: string, rendered: record, summary: record, state: string, author: record, source: record, destination: record, merge_commit: record, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record, reason: string, created_on: string, updated_on: string, reviewers: list, participants: list, draft: bool, queued: bool, mergeable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests
# --links shape: {self?: record, html?: record, commits?: record, approve?: record, diff?: record, diffstat?: record, comments?: record, activity?: record, merge?: record, decline?: record}
# --rendered shape: {title?: record, description?: record, reason?: record}
# --summary shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
# --source shape: {repository?: any, branch?: record, commit?: record}
# --destination shape: {repository?: any, branch?: record, commit?: record}
# --merge_commit shape: {hash?: string}
# --reviewers item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
# --participants item shape: {type: string, user?: any, role?: "PARTICIPANT"|"REVIEWER", approved?: bool, state?: "approved"|"changes_requested"|"", participated_on?: string}
export def "repositories-pullrequests post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record, commits?: record, approve?: record, diff?: record, diffstat?: record, comments?: record, activity?: record, merge?: record, decline?: record}
  --id: int # The pull request's unique ID. Note that pull request IDs are only unique within their associated repository.
  --title: string # Title of the pull request.
  --rendered: record # User provided pull request text, interpreted in a markup language and rendered in HTML — shape: {title?: record, description?: record, reason?: record}
  --summary: record # shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
  --state: string@state-completer-3 # The pull request's current status.
  --author: any
  --body-source: record # shape: {repository?: any, branch?: record, commit?: record}
  --destination: record # shape: {repository?: any, branch?: record, commit?: record}
  --merge-commit: record # shape: {hash?: string}
  --comment-count: int # The number of comments for a specific pull request.
  --task-count: int # The number of open tasks for a specific pull request.
  --close-source-branch: oneof<nothing, bool> # A boolean flag indicating if merging the pull request closes the source branch.
  --closed-by: any
  --reason: string # Explains why a pull request was declined. This field is only applicable to pull requests in rejected state.
  --created-on: string # The ISO8601 timestamp the request was created. (format: date-time)
  --updated-on: string # The ISO8601 timestamp the request was last updated. (format: date-time)
  --reviewers: list # The list of users that were added as reviewers on this pull request when it was created. For performance reasons, the API only includes this list on a pull request's `self` URL. — item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
  --participants: list #         The list of users that are collaborating on this pull request.         Collaborators are user that:          * are added to the pull request as a reviewer (part of the reviewers           list)         * are not explicit reviewers, but have commented on the pull request         * are not explicit reviewers, but have approved the pull request          Each user is wrapped in an object that indicates the user's role and         whether they have approved the pull request. For performance reasons,         the API only returns this list when an API requests a pull request by         id.          — item shape: {type: string, user?: any, role?: "PARTICIPANT"|"REVIEWER", approved?: bool, state?: "approved"|"changes_requested"|"", participated_on?: string}
  --draft: oneof<nothing, bool> # A boolean flag indicating whether the pull request is a draft.
  --queued: oneof<nothing, bool> # A boolean flag indicating whether the pull request is queued
  --mergeable: oneof<nothing, bool> # A boolean flag indicating whether the pull request passes all merge checks
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, commits: record<href: string, name: string>, approve: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, comments: record<href: string, name: string>, activity: record<href: string, name: string>, merge: record<href: string, name: string>, decline: record<href: string, name: string>>, id: int, title: string, rendered: record<title: record<raw: string, markup: string, html: string>, description: record<raw: string, markup: string, html: string>, reason: record<raw: string, markup: string, html: string>>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, source: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, destination: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, participants: table<type: string, user: record, role: string, approved: bool, state: string, participated_on: string>, draft: bool, queued: bool, mergeable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests")
  let body = {type: $type, links: $links, id: $id, title: $title, rendered: $rendered, summary: $summary, state: $state, author: $author, source: $body_source, destination: $destination, merge_commit: $merge_commit, comment_count: $comment_count, task_count: $task_count, close_source_branch: $close_source_branch, closed_by: $closed_by, reason: $reason, created_on: $created_on, updated_on: $updated_on, reviewers: $reviewers, participants: $participants, draft: $draft, queued: $queued, mergeable: $mergeable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a pull request activity log
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/activity
export def "repositories-pullrequests-activity list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/activity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
export def "repositories-pullrequests get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, commits: record<href: string, name: string>, approve: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, comments: record<href: string, name: string>, activity: record<href: string, name: string>, merge: record<href: string, name: string>, decline: record<href: string, name: string>>, id: int, title: string, rendered: record<title: record<raw: string, markup: string, html: string>, description: record<raw: string, markup: string, html: string>, reason: record<raw: string, markup: string, html: string>>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, source: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, destination: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, participants: table<type: string, user: record, role: string, approved: bool, state: string, participated_on: string>, draft: bool, queued: bool, mergeable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a pull request
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
# --links shape: {self?: record, html?: record, commits?: record, approve?: record, diff?: record, diffstat?: record, comments?: record, activity?: record, merge?: record, decline?: record}
# --rendered shape: {title?: record, description?: record, reason?: record}
# --summary shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
# --source shape: {repository?: any, branch?: record, commit?: record}
# --destination shape: {repository?: any, branch?: record, commit?: record}
# --merge_commit shape: {hash?: string}
# --reviewers item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
# --participants item shape: {type: string, user?: any, role?: "PARTICIPANT"|"REVIEWER", approved?: bool, state?: "approved"|"changes_requested"|"", participated_on?: string}
export def "repositories-pullrequests put" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record, commits?: record, approve?: record, diff?: record, diffstat?: record, comments?: record, activity?: record, merge?: record, decline?: record}
  --id: int # The pull request's unique ID. Note that pull request IDs are only unique within their associated repository.
  --title: string # Title of the pull request.
  --rendered: record # User provided pull request text, interpreted in a markup language and rendered in HTML — shape: {title?: record, description?: record, reason?: record}
  --summary: record # shape: {raw?: string, markup?: "markdown"|"creole"|"plaintext", html?: string}
  --state: string@state-completer-3 # The pull request's current status.
  --author: any
  --body-source: record # shape: {repository?: any, branch?: record, commit?: record}
  --destination: record # shape: {repository?: any, branch?: record, commit?: record}
  --merge-commit: record # shape: {hash?: string}
  --comment-count: int # The number of comments for a specific pull request.
  --task-count: int # The number of open tasks for a specific pull request.
  --close-source-branch: oneof<nothing, bool> # A boolean flag indicating if merging the pull request closes the source branch.
  --closed-by: any
  --reason: string # Explains why a pull request was declined. This field is only applicable to pull requests in rejected state.
  --created-on: string # The ISO8601 timestamp the request was created. (format: date-time)
  --updated-on: string # The ISO8601 timestamp the request was last updated. (format: date-time)
  --reviewers: list # The list of users that were added as reviewers on this pull request when it was created. For performance reasons, the API only includes this list on a pull request's `self` URL. — item shape: {type: string, links?: record, created_on?: string, display_name?: string, uuid?: string}
  --participants: list #         The list of users that are collaborating on this pull request.         Collaborators are user that:          * are added to the pull request as a reviewer (part of the reviewers           list)         * are not explicit reviewers, but have commented on the pull request         * are not explicit reviewers, but have approved the pull request          Each user is wrapped in an object that indicates the user's role and         whether they have approved the pull request. For performance reasons,         the API only returns this list when an API requests a pull request by         id.          — item shape: {type: string, user?: any, role?: "PARTICIPANT"|"REVIEWER", approved?: bool, state?: "approved"|"changes_requested"|"", participated_on?: string}
  --draft: oneof<nothing, bool> # A boolean flag indicating whether the pull request is a draft.
  --queued: oneof<nothing, bool> # A boolean flag indicating whether the pull request is queued
  --mergeable: oneof<nothing, bool> # A boolean flag indicating whether the pull request passes all merge checks
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, commits: record<href: string, name: string>, approve: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, comments: record<href: string, name: string>, activity: record<href: string, name: string>, merge: record<href: string, name: string>, decline: record<href: string, name: string>>, id: int, title: string, rendered: record<title: record<raw: string, markup: string, html: string>, description: record<raw: string, markup: string, html: string>, reason: record<raw: string, markup: string, html: string>>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, source: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, destination: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, participants: table<type: string, user: record, role: string, approved: bool, state: string, participated_on: string>, draft: bool, queued: bool, mergeable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)")
  let body = {type: $type, links: $links, id: $id, title: $title, rendered: $rendered, summary: $summary, state: $state, author: $author, source: $body_source, destination: $destination, merge_commit: $merge_commit, comment_count: $comment_count, task_count: $task_count, close_source_branch: $close_source_branch, closed_by: $closed_by, reason: $reason, created_on: $created_on, updated_on: $updated_on, reviewers: $reviewers, participants: $participants, draft: $draft, queued: $queued, mergeable: $mergeable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a pull request activity log
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/activity
export def "repositories-pullrequests-activity get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/activity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unapprove a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
export def "repositories-pullrequests-approve delete" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
export def "repositories-pullrequests-approve post" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, role: string, approved: bool, state: string, participated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List comments on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
export def "repositories-pullrequests-comments list" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<pullrequest: record, resolution: record, pending: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/comments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a comment on a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
# --resolution shape: {type: string, user?: any, created_on?: string}
export def "repositories-pullrequests-comments post" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pullrequest: any
  --resolution: record # The resolution object for a Comment. — shape: {type: string, user?: any, created_on?: string}
  --pending: oneof<nothing, bool>
]: any -> record<pullrequest: record<type: string, links: record<self: record, html: record, commits: record, approve: record, diff: record, diffstat: record, comments: record, activity: record, merge: record, decline: record>, id: int, title: string, rendered: record<title: record, description: record, reason: record>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, source: record<repository: record, branch: record, commit: record>, destination: record<repository: record, branch: record, commit: record>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: list<record>, participants: list<record>, draft: bool, queued: bool, mergeable: bool>, resolution: record<type: string, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, created_on: string>, pending: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/comments")
  let body = {pullrequest: $pullrequest, resolution: $resolution, pending: $pending} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a comment on a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
export def "repositories-pullrequests-comments delete" [
  comment_id: int
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a comment on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
export def "repositories-pullrequests-comments get" [
  comment_id: int
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pullrequest: record<type: string, links: record<self: record, html: record, commits: record, approve: record, diff: record, diffstat: record, comments: record, activity: record, merge: record, decline: record>, id: int, title: string, rendered: record<title: record, description: record, reason: record>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, source: record<repository: record, branch: record, commit: record>, destination: record<repository: record, branch: record, commit: record>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: list<record>, participants: list<record>, draft: bool, queued: bool, mergeable: bool>, resolution: record<type: string, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, created_on: string>, pending: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a comment on a pull request
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
# --resolution shape: {type: string, user?: any, created_on?: string}
export def "repositories-pullrequests-comments put" [
  comment_id: int
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pullrequest: any
  --resolution: record # The resolution object for a Comment. — shape: {type: string, user?: any, created_on?: string}
  --pending: oneof<nothing, bool>
]: any -> record<pullrequest: record<type: string, links: record<self: record, html: record, commits: record, approve: record, diff: record, diffstat: record, comments: record, activity: record, merge: record, decline: record>, id: int, title: string, rendered: record<title: record, description: record, reason: record>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, source: record<repository: record, branch: record, commit: record>, destination: record<repository: record, branch: record, commit: record>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: list<record>, participants: list<record>, draft: bool, queued: bool, mergeable: bool>, resolution: record<type: string, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, created_on: string>, pending: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/comments/($comment_id)")
  let body = {pullrequest: $pullrequest, resolution: $resolution, pending: $pending} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reopen a comment thread
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}/resolve
export def "repositories-pullrequests-comments-resolve delete" [
  comment_id: int
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/comments/($comment_id)/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve a comment thread
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}/resolve
export def "repositories-pullrequests-comments-resolve post" [
  comment_id: int
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, created_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/comments/($comment_id)/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commits on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/commits
export def "repositories-pullrequests-commits get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/commits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file conflicts for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/conflicts
export def "repositories-pullrequests-conflicts get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/conflicts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Decline a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/decline
export def "repositories-pullrequests-decline post" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, commits: record<href: string, name: string>, approve: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, comments: record<href: string, name: string>, activity: record<href: string, name: string>, merge: record<href: string, name: string>, decline: record<href: string, name: string>>, id: int, title: string, rendered: record<title: record<raw: string, markup: string, html: string>, description: record<raw: string, markup: string, html: string>, reason: record<raw: string, markup: string, html: string>>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, source: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, destination: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, participants: table<type: string, user: record, role: string, approved: bool, state: string, participated_on: string>, draft: bool, queued: bool, mergeable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/decline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List changes in a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diff
export def "repositories-pullrequests-diff get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/diff")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the diff stat for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diffstat
export def "repositories-pullrequests-diffstat get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/diffstat")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge
export def "repositories-pullrequests-merge post" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: oneof<nothing, bool> # Default value is false.   When set to true, runs merge asynchronously and immediately returns a 202 with polling link to the task-status API in the Location header.   When set to false, runs merge and waits for it to complete, returning 200 when it succeeds. If the duration of the merge exceeds a timeout threshold, the API returns a 202 with polling link to the task-status API in the Location header.
  type: string
  --message: string # The commit message that will be used on the resulting commit. Note that the size of the message is limited to 128 KiB.
  --close-source-branch: oneof<nothing, bool> # Whether the source branch should be deleted. If this is not provided, we fallback to the value used when the pull request was created, which defaults to False
  --merge-strategy: string@merge-strategy-completer # The merge strategy that will be used to merge the pull request. (default: merge_commit)
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, commits: record<href: string, name: string>, approve: record<href: string, name: string>, diff: record<href: string, name: string>, diffstat: record<href: string, name: string>, comments: record<href: string, name: string>, activity: record<href: string, name: string>, merge: record<href: string, name: string>, decline: record<href: string, name: string>>, id: int, title: string, rendered: record<title: record<raw: string, markup: string, html: string>, description: record<raw: string, markup: string, html: string>, reason: record<raw: string, markup: string, html: string>>, summary: record<raw: string, markup: string, html: string>, state: string, author: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, source: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, destination: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, branch: record<name: string, merge_strategies: list, default_merge_strategy: string>, commit: record<hash: string>>, merge_commit: record<hash: string>, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, reason: string, created_on: string, updated_on: string, reviewers: table<type: string, links: record, created_on: string, display_name: string, uuid: string>, participants: table<type: string, user: record, role: string, approved: bool, state: string, participated_on: string>, draft: bool, queued: bool, mergeable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/merge" $qp)
  let body = {type: $type, message: $message, close_source_branch: $close_source_branch, merge_strategy: $merge_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the merge task status for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge/task-status/{task_id}
export def "repositories-pullrequests-merge-task-status get" [
  pull_request_id: int
  repo_slug: string
  task_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/merge/task-status/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the patch for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/patch
export def "repositories-pullrequests-patch get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/patch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove change request for a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
export def "repositories-pullrequests-request-changes delete" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/request-changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request changes for a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
export def "repositories-pullrequests-request-changes post" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, role: string, approved: bool, state: string, participated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/request-changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List commit statuses for a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/statuses
export def "repositories-pullrequests-statuses get" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). Defaults to `created_on`.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, key: string, refname: string, url: string, state: string, name: string, description: string, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tasks on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks
export def "repositories-pullrequests-tasks list" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --qp-sort: string #  Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). Defaults to `created_on`.
  --pagelen: int #  Current number of objects on the existing page. The default value is 10 with 100 being the maximum allowed value. Individual APIs may enforce different values.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<comment: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a task on a pull request
#
# POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks
# --content shape: {raw: string}
export def "repositories-pullrequests-tasks post" [
  pull_request_id: int
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: record # task raw content — shape: {raw: string}
  --comment: any
  --pending: oneof<nothing, bool>
]: any -> record<comment: record<type: string, id: int, created_on: string, updated_on: string, content: record<raw: string, markup: string, html: string>, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, deleted: bool, parent: any, inline: record<from: int, to: int, start_from: int, start_to: int, path: string>, links: record<self: record, html: record, code: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/tasks")
  let body = {content: $content, comment: $comment, pending: $pending} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a task on a pull request
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks/{task_id}
export def "repositories-pullrequests-tasks delete" [
  pull_request_id: int
  repo_slug: string
  task_id: int
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a task on a pull request
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks/{task_id}
export def "repositories-pullrequests-tasks get" [
  pull_request_id: int
  repo_slug: string
  task_id: int
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<comment: record<type: string, id: int, created_on: string, updated_on: string, content: record<raw: string, markup: string, html: string>, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, deleted: bool, parent: any, inline: record<from: int, to: int, start_from: int, start_to: int, path: string>, links: record<self: record, html: record, code: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a task on a pull request
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks/{task_id}
# --content shape: {raw: string}
export def "repositories-pullrequests-tasks put" [
  pull_request_id: int
  repo_slug: string
  task_id: int
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: record # task raw content — shape: {raw: string}
  --state: string@state-completer-4
]: any -> record<comment: record<type: string, id: int, created_on: string, updated_on: string, content: record<raw: string, markup: string, html: string>, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, deleted: bool, parent: any, inline: record<from: int, to: int, start_from: int, start_to: int, path: string>, links: record<self: record, html: record, code: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pull_request_id)/tasks/($task_id)")
  let body = {content: $content, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a pull request application property
#
# PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: updatePullRequestHostedPropertyValue
export def "repositories-pullrequests-properties updatePullRequestHostedPropertyValue" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pullrequest_id)/properties/($app_key)/($property_name)")
  let body = {_attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a pull request application property
#
# DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: deletePullRequestHostedPropertyValue
export def "repositories-pullrequests-properties delete" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pullrequest_id)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pull request application property
#
# GET /repositories/{workspace}/{repo_slug}/pullrequests/{pullrequest_id}/properties/{app_key}/{property_name}
# operationId: getPullRequestHostedPropertyValue
export def "repositories-pullrequests-properties get" [
  workspace: string
  repo_slug: string
  pullrequest_id: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/pullrequests/($pullrequest_id)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List branches and tags
#
# GET /repositories/{workspace}/{repo_slug}/refs
export def "repositories-refs get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for refs in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['1.1', '1.2', '1.10'] instead of ['1.1', '1.10', '1.2'].
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string, target: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List open branches
#
# GET /repositories/{workspace}/{repo_slug}/refs/branches
export def "repositories-refs-branches list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for branches in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['branch1', 'branch2', 'branch10'] instead of ['branch1', 'branch10', 'branch2'].
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string, target: record, merge_strategies: list, default_merge_strategy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/branches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a branch
#
# POST /repositories/{workspace}/{repo_slug}/refs/branches
export def "repositories-refs-branches post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, commits: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, target: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: any>, participants: list<record>>, merge_strategies: list<string>, default_merge_strategy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a branch
#
# DELETE /repositories/{workspace}/{repo_slug}/refs/branches/{name}
export def "repositories-refs-branches delete" [
  name: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/branches/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a branch
#
# GET /repositories/{workspace}/{repo_slug}/refs/branches/{name}
export def "repositories-refs-branches get" [
  name: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, commits: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, target: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: any>, participants: list<record>>, merge_strategies: list<string>, default_merge_strategy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/branches/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tags
#
# GET /repositories/{workspace}/{repo_slug}/refs/tags
export def "repositories-refs-tags list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Field by which the results should be sorted as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering). The `name` field is handled specially for tags in that, if specified as the sort field, it uses a natural sort order instead of the default lexicographical sort order. For example, it will return ['1.1', '1.2', '1.10'] instead of ['1.1', '1.10', '1.2'].
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string, target: record, message: string, date: string, tagger: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tag
#
# POST /repositories/{workspace}/{repo_slug}/refs/tags
# --links shape: {self?: record, commits?: record, html?: record}
export def "repositories-refs-tags post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, commits?: record, html?: record}
  --name: string # The name of the ref.
  --target: any
  --message: string # The message associated with the tag, if available.
  --date: string # The date that the tag was created, if available (format: date-time)
  --tagger: any
]: any -> record<type: string, links: record<self: record<href: string, name: string>, commits: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, target: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, participants: list<record>>, message: string, date: string, tagger: record<type: string, raw: string, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/tags")
  let body = {type: $type, links: $links, name: $name, target: $target, message: $message, date: $date, tagger: $tagger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag
#
# DELETE /repositories/{workspace}/{repo_slug}/refs/tags/{name}
export def "repositories-refs-tags delete" [
  name: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/tags/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a tag
#
# GET /repositories/{workspace}/{repo_slug}/refs/tags/{name}
export def "repositories-refs-tags get" [
  name: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, commits: record<href: string, name: string>, html: record<href: string, name: string>>, name: string, target: record<repository: record<type: string, links: record, uuid: string, full_name: string, is_private: bool, parent: any, scm: string, owner: record, name: string, description: string, created_on: string, updated_on: string, size: int, language: string, has_issues: bool, has_wiki: bool, fork_policy: string, project: record, mainbranch: record>, participants: list<record>>, message: string, date: string, tagger: record<type: string, raw: string, user: record<type: string, links: record, created_on: string, display_name: string, uuid: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/refs/tags/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the root directory of the main branch
#
# GET /repositories/{workspace}/{repo_slug}/src
export def "repositories-src get-by-repo_slug-workspace" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Instead of returning the file's contents, return the (json) meta data for it.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, path: string, commit: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/src" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a commit by uploading a file
#
# POST /repositories/{workspace}/{repo_slug}/src
export def "repositories-src post" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string # The commit message. When omitted, Bitbucket uses a canned string.
  --author: string #  The raw string to be used as the new commit's author. This string follows the format `Erik van Zijst <evzijst@atlassian.com>`.  When omitted, Bitbucket uses the authenticated user's full/display name and primary email address. Commits cannot be created anonymously.
  --parents: string #  #### Deprecation Notice: Support for specifying multiple parent commits is deprecated and will be removed in a future release. Only a single SHA1 is accepted.  A SHA1 of the commit that should be the parent of the newly created commit. When omitted, the new commit will inherit from and become a child of the main branch's tip/HEAD commit.
  --files: string #  Optional field that declares the files that the request is manipulating. When adding a new file to a repo, or when overwriting an existing file, the client can just upload the full contents of the file in a normal form field and the use of this `files` meta data field is redundant. However, when the `files` field contains a file path that does not have a corresponding, identically-named form field, then Bitbucket interprets that as the client wanting to replace the named file with the null set and the file is deleted instead.  Paths in the repo that are referenced in neither files nor an individual file field, remain unchanged and carry over from the parent to the new commit.  This API does not support renaming as an explicit feature. To rename a file, simply delete it and recreate it under the new name in the same commit.
  --branch: string #  The name of the branch that the new commit should be created on. When omitted, the commit will be created on top of the main branch and will become the main branch's new head.  When a branch name is provided that already exists in the repo, then the commit will be created on top of that branch. In this case, *if* a parent SHA1 was also provided, then it is asserted that the parent is the branch's tip/HEAD at the time the request is made. When this is not the case, a 409 is returned.  When a new branch name is specified (that does not already exist in the repo), and no parent SHA1s are provided, then the new commit will inherit from the current main branch's tip/HEAD commit, but not advance the main branch. The new commit will be the new branch. When the request *also* specifies a parent SHA1, then the new commit and branch are created directly on top of the parent commit, regardless of the state of the main branch.  When a branch name is not specified, but a parent SHA1 is provided, then Bitbucket asserts that it represents the main branch's current HEAD/tip, or a 409 is returned.  When a branch name is not specified and the repo is empty, the new commit will become the repo's root commit and will be on the main branch.  When a branch name is specified and the repo is empty, the new commit will become the repo's root commit and also define the repo's main branch going forward.  This API cannot be used to create additional root commits in non-empty repos.  The branch field cannot be repeated.  As a side effect, this API can be used to create a new branch without modifying any files, by specifying a new branch name in this field, together with `parents`, but omitting the `files` fields, while not sending any files. This will create a new commit and branch with the same contents as the first parent. The diff of this commit against its first parent will be empty.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "message" $message "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "parents" $parents "scalar") (serialize-qp "files" $files "scalar") (serialize-qp "branch" $branch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/src" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get file or directory contents
#
# GET /repositories/{workspace}/{repo_slug}/src/{commit}/{path}
export def "repositories-src get-by-commit-path-repo_slug-workspace" [
  commit: string
  path: string
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer-1 # If 'meta' is provided, returns the (json) meta data for the contents of the file.  If 'rendered' is provided, returns the contents of a non-binary file in HTML-formatted rendered markup. The 'rendered' option only supports these filetypes: `.md`, `.markdown`, `.mkd`, `.mkdn`, `.mdown`, `.text`, `.rst`, and `.textile`. Since Git does not generally track what text encoding scheme is used, this endpoint attempts to detect the most appropriate character encoding. While usually correct, determining the character encoding can be ambiguous which in exceptional cases can lead to misinterpretation of the characters. As such, the raw element in the response object should not be treated as equivalent to the file's actual contents.
  --q: string # Optional filter expression as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string # Optional sorting parameter as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
  --max-depth: int # If provided, returns the contents of the repository and its subdirectories recursively until the specified max_depth of nested directories. When omitted, this defaults to 1.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, path: string, commit: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max_depth" $max_depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/src/($commit)/($path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List defined versions for issues
#
# GET /repositories/{workspace}/{repo_slug}/versions
# DEPRECATED
@deprecated
export def "repositories-versions list" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, name: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a defined version for issues
#
# GET /repositories/{workspace}/{repo_slug}/versions/{version_id}
# DEPRECATED
@deprecated
export def "repositories-versions get" [
  repo_slug: string
  version_id: int
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, name: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repositories watchers
#
# GET /repositories/{workspace}/{repo_slug}/watchers
export def "repositories-watchers get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repositories/($workspace)/($repo_slug)/watchers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List snippets
#
# GET /snippets
# DEPRECATED
@deprecated
export def "snippets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-1 # Filter down the result based on the authenticated user's role (`owner`, `contributor`, or `member`).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record, creator: record, is_private: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/snippets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a snippet
#
# POST /snippets
export def "snippets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --id: int
  --title: string
  --scm: string@scm-completer # The DVCS used to store the snippet.
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --owner: any
  --creator: any
  --is-private: oneof<nothing, bool>
]: any -> record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, is_private: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snippets")
  let body = {type: $type, id: $id, title: $title, scm: $scm, created_on: $created_on, updated_on: $updated_on, owner: $owner, creator: $creator, is_private: $is_private} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List snippets in a workspace
#
# GET /snippets/{workspace}
export def "snippets get-by-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-1 # Filter down the result based on the authenticated user's role (`owner`, `contributor`, or `member`).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record, creator: record, is_private: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/snippets/($workspace)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a snippet for a workspace
#
# POST /snippets/{workspace}
export def "snippets post-by-workspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --id: int
  --title: string
  --scm: string@scm-completer # The DVCS used to store the snippet.
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --owner: any
  --creator: any
  --is-private: oneof<nothing, bool>
]: any -> record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, is_private: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)")
  let body = {type: $type, id: $id, title: $title, scm: $scm, created_on: $created_on, updated_on: $updated_on, owner: $owner, creator: $creator, is_private: $is_private} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}
export def "snippets delete-by-encoded_id-workspace" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a snippet
#
# GET /snippets/{workspace}/{encoded_id}
export def "snippets get-by-encoded_id-workspace" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, is_private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a snippet
#
# PUT /snippets/{workspace}/{encoded_id}
export def "snippets put-by-encoded_id-workspace" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, is_private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List comments on a snippet
#
# GET /snippets/{workspace}/{encoded_id}/comments
export def "snippets-comments list" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, snippet: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/comments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a comment on a snippet
#
# POST /snippets/{workspace}/{encoded_id}/comments
# --links shape: {self?: record, html?: record}
export def "snippets-comments post" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record}
  --snippet: any
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>>, snippet: record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, is_private: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/comments")
  let body = {type: $type, links: $links, snippet: $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a comment on a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/comments/{comment_id}
export def "snippets-comments delete" [
  comment_id: int
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a comment on a snippet
#
# GET /snippets/{workspace}/{encoded_id}/comments/{comment_id}
export def "snippets-comments get" [
  comment_id: int
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>>, snippet: record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, is_private: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a comment on a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/comments/{comment_id}
# --links shape: {self?: record, html?: record}
export def "snippets-comments put" [
  comment_id: int
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {self?: record, html?: record}
  --snippet: any
]: any -> record<type: string, links: record<self: record<href: string, name: string>, html: record<href: string, name: string>>, snippet: record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, is_private: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/comments/($comment_id)")
  let body = {type: $type, links: $links, snippet: $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List snippet changes
#
# GET /snippets/{workspace}/{encoded_id}/commits
export def "snippets-commits list" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<links: record, snippet: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/commits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a previous snippet change
#
# GET /snippets/{workspace}/{encoded_id}/commits/{revision}
export def "snippets-commits get" [
  encoded_id: string
  revision: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<links: record<self: record<href: string, name: string>, html: record<href: string, name: string>, diff: record<href: string, name: string>>, snippet: record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, is_private: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/commits/($revision)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a snippet's raw file at HEAD
#
# GET /snippets/{workspace}/{encoded_id}/files/{path}
export def "snippets-files list" [
  encoded_id: string
  path: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/files/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop watching a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/watch
export def "snippets-watch delete" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if the current user is watching a snippet
#
# GET /snippets/{workspace}/{encoded_id}/watch
export def "snippets-watch get" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Watch a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/watch
export def "snippets-watch put" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/watch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users watching a snippet
#
# GET /snippets/{workspace}/{encoded_id}/watchers
# DEPRECATED
@deprecated
export def "snippets-watchers get" [
  encoded_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/watchers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a previous revision of a snippet
#
# DELETE /snippets/{workspace}/{encoded_id}/{node_id}
export def "snippets delete-by-encoded_id-node_id-workspace" [
  encoded_id: string
  node_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/($node_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a previous revision of a snippet
#
# GET /snippets/{workspace}/{encoded_id}/{node_id}
export def "snippets get-by-encoded_id-node_id-workspace" [
  encoded_id: string
  node_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, is_private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/($node_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a previous revision of a snippet
#
# PUT /snippets/{workspace}/{encoded_id}/{node_id}
export def "snippets put-by-encoded_id-node_id-workspace" [
  encoded_id: string
  node_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<type: string, id: int, title: string, scm: string, created_on: string, updated_on: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, creator: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, is_private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/($node_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a snippet's raw file
#
# GET /snippets/{workspace}/{encoded_id}/{node_id}/files/{path}
export def "snippets-files get" [
  encoded_id: string
  node_id: string
  path: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/($node_id)/files/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get snippet changes between versions
#
# GET /snippets/{workspace}/{encoded_id}/{revision}/diff
export def "snippets-diff get" [
  encoded_id: string
  revision: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # When used, only one the diff of the specified file will be returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/($revision)/diff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get snippet patch between versions
#
# GET /snippets/{workspace}/{encoded_id}/{revision}/patch
export def "snippets-patch get" [
  encoded_id: string
  revision: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/snippets/($workspace)/($encoded_id)/($revision)/patch")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List variables for an account
#
# GET /teams/{username}/pipelines_config/variables
# DEPRECATED
# operationId: getPipelineVariablesForTeam
@deprecated
export def "teams-pipelines-config-variables list" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, key: string, value: string, secured: bool>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($username)/pipelines_config/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a variable for a user
#
# POST /teams/{username}/pipelines_config/variables
# DEPRECATED
# operationId: createPipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables createPipelineVariableForTeam" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($username)/pipelines_config/variables")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a variable for a team
#
# GET /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: getPipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables get" [
  username: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($username)/pipelines_config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a variable for a team
#
# PUT /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: updatePipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables updatePipelineVariableForTeam" [
  username: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($username)/pipelines_config/variables/($variable_uuid)")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a variable for a team
#
# DELETE /teams/{username}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: deletePipelineVariableForTeam
@deprecated
export def "teams-pipelines-config-variables delete" [
  username: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($username)/pipelines_config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for code in a team's repositories
#
# GET /teams/{username}/search/code
# DEPRECATED
# operationId: searchTeam
@deprecated
export def "teams-search-code searchTeam" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search-query: string # The search query
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> record<size: int, page: int, pagelen: int, query_substituted: bool, next: string, previous: string, values: table<type: string, content_match_count: int, content_matches: list, path_matches: list, file: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_query" $search_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($username)/search/code" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current user
#
# GET /user
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<avatar: record<href: string, name: string>>, created_on: string, display_name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List email addresses for current user
#
# GET /user/emails
export def "user-emails list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, error: record<message: string, detail: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/emails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an email address for current user
#
# GET /user/emails/{email}
export def "user-emails get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, error: record<message: string, detail: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/emails/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repository permissions for a user
#
# GET /user/permissions/repositories
# DEPRECATED
@deprecated
export def "user-permissions-repositories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, permission: string, user: record, repository: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/permissions/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspaces for the current user
#
# GET /user/permissions/workspaces
# DEPRECATED
@deprecated
export def "user-permissions-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --qp-sort: string #  Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/permissions/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspaces for the current user
#
# GET /user/workspaces
export def "user-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string # Name of a response property to sort results (only slug is supported).
  --administrator: oneof<nothing, bool> # Filter workspaces based on which ones the caller has admin permissions or not.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, administrator: bool, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "administrator" $administrator "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user permission on a workspace
#
# GET /user/workspaces/{workspace}/permission
export def "user-workspaces-permission get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, workspace: record<type: string, links: record<avatar: record, html: record, members: record, owners: record, projects: record, repositories: record, snippets: record, self: record>, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user/workspaces/($workspace)/permission")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List repository permissions in a workspace for a user
#
# GET /user/workspaces/{workspace}/permissions/repositories
export def "user-workspaces-permissions-repositories get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, permission: string, user: record, repository: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user/workspaces/($workspace)/permissions/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /users/{selected_user}
export def "users get" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<avatar: record<href: string, name: string>>, created_on: string, display_name: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List GPG keys
#
# GET /users/{selected_user}/gpg-keys
export def "users-gpg-keys list" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, owner: record, key: string, key_id: string, fingerprint: string, parent_fingerprint: string, name: string, expires_on: string, created_on: string, added_on: string, last_used: string, subkeys: list, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/gpg-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new GPG key
#
# POST /users/{selected_user}/gpg-keys
# --subkeys item shape: {type: string, owner?: any, key?: string, key_id?: string, fingerprint?: string, parent_fingerprint?: string, name?: string, expires_on?: string, created_on?: string, added_on?: string, last_used?: string, subkeys?: list, links?: record}
# --links shape: {self?: record}
export def "users-gpg-keys post" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --owner: any
  --key: string # The GPG key value in X format.
  --key-id: string # The unique identifier for the GPG key
  --fingerprint: string # The GPG key fingerprint.
  --parent-fingerprint: string # The fingerprint of the parent key. This value is null unless the current key is a subkey.
  --name: string # The user-defined label for the GPG key
  --expires-on: string # format: date-time
  --created-on: string # format: date-time
  --added-on: string # format: date-time
  --last-used: string # format: date-time
  --subkeys: list # item shape: {type: string, owner?: any, key?: string, key_id?: string, fingerprint?: string, parent_fingerprint?: string, name?: string, expires_on?: string, created_on?: string, added_on?: string, last_used?: string, subkeys?: list, links?: record}
  --links: record # shape: {self?: record}
]: any -> record<type: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, key: string, key_id: string, fingerprint: string, parent_fingerprint: string, name: string, expires_on: string, created_on: string, added_on: string, last_used: string, subkeys: list<any>, links: record<self: record<href: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/gpg-keys")
  let body = {type: $type, owner: $owner, key: $key, key_id: $key_id, fingerprint: $fingerprint, parent_fingerprint: $parent_fingerprint, name: $name, expires_on: $expires_on, created_on: $created_on, added_on: $added_on, last_used: $last_used, subkeys: $subkeys, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a GPG key
#
# DELETE /users/{selected_user}/gpg-keys/{fingerprint}
export def "users-gpg-keys delete" [
  fingerprint: string
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/gpg-keys/($fingerprint)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a GPG key
#
# GET /users/{selected_user}/gpg-keys/{fingerprint}
export def "users-gpg-keys get" [
  fingerprint: string
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, key: string, key_id: string, fingerprint: string, parent_fingerprint: string, name: string, expires_on: string, created_on: string, added_on: string, last_used: string, subkeys: list<any>, links: record<self: record<href: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/gpg-keys/($fingerprint)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List variables for a user
#
# GET /users/{selected_user}/pipelines_config/variables
# DEPRECATED
# operationId: getPipelineVariablesForUser
@deprecated
export def "users-pipelines-config-variables list" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, key: string, value: string, secured: bool>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/pipelines_config/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a variable for a user
#
# POST /users/{selected_user}/pipelines_config/variables
# DEPRECATED
# operationId: createPipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables createPipelineVariableForUser" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/pipelines_config/variables")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a variable for a user
#
# GET /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: getPipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables get" [
  selected_user: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/pipelines_config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a variable for a user
#
# PUT /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: updatePipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables updatePipelineVariableForUser" [
  selected_user: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/pipelines_config/variables/($variable_uuid)")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a variable for a user
#
# DELETE /users/{selected_user}/pipelines_config/variables/{variable_uuid}
# DEPRECATED
# operationId: deletePipelineVariableForUser
@deprecated
export def "users-pipelines-config-variables delete" [
  selected_user: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/pipelines_config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user application property
#
# PUT /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: updateUserHostedPropertyValue
export def "users-properties updateUserHostedPropertyValue" [
  selected_user: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/properties/($app_key)/($property_name)")
  let body = {_attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a user application property
#
# DELETE /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: deleteUserHostedPropertyValue
export def "users-properties delete" [
  selected_user: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user application property
#
# GET /users/{selected_user}/properties/{app_key}/{property_name}
# operationId: retrieveUserHostedPropertyValue
export def "users-properties retrieveUserHostedPropertyValue" [
  selected_user: string
  app_key: string
  property_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_attributes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/properties/($app_key)/($property_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for code in a user's repositories
#
# GET /users/{selected_user}/search/code
# DEPRECATED
# operationId: searchAccount
@deprecated
export def "users-search-code searchAccount" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search-query: string # The search query
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> record<size: int, page: int, pagelen: int, query_substituted: bool, next: string, previous: string, values: table<type: string, content_match_count: int, content_matches: list, path_matches: list, file: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_query" $search_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($selected_user)/search/code" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SSH keys
#
# GET /users/{selected_user}/ssh-keys
export def "users-ssh-keys list" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<owner: record, expires_on: string, fingerprint: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/ssh-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new SSH key
#
# POST /users/{selected_user}/ssh-keys
export def "users-ssh-keys post" [
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-on: string # The date or date-time of when the key will expire, in [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) format. Example: `YYYY-MM-DDTHH:mm:ss.sssZ`
  --owner: any
  --expires-on: string # format: date-time
  --fingerprint: string # The SSH key fingerprint in SHA-256 format.
]: any -> record<owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, expires_on: string, fingerprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expires_on" $expires_on "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($selected_user)/ssh-keys" $qp)
  let body = {owner: $owner, expires_on: $expires_on, fingerprint: $fingerprint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a SSH key
#
# DELETE /users/{selected_user}/ssh-keys/{key_id}
export def "users-ssh-keys delete" [
  key_id: string
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/ssh-keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a SSH key
#
# GET /users/{selected_user}/ssh-keys/{key_id}
export def "users-ssh-keys get" [
  key_id: string
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, expires_on: string, fingerprint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/ssh-keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a SSH key
#
# PUT /users/{selected_user}/ssh-keys/{key_id}
export def "users-ssh-keys put" [
  key_id: string
  selected_user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: any
  --expires-on: string # format: date-time
  --fingerprint: string # The SSH key fingerprint in SHA-256 format.
]: any -> record<owner: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, expires_on: string, fingerprint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($selected_user)/ssh-keys/($key_id)")
  let body = {owner: $owner, expires_on: $expires_on, fingerprint: $fingerprint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspaces for user
#
# GET /workspaces
# DEPRECATED
@deprecated
export def "workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer-2 #              Filters the workspaces based on the authenticated user's role on each workspace.              * **member**: returns a list of all the workspaces which the caller is a member of                 at least one workspace group or repository             * **collaborator**: returns a list of workspaces which the caller has write access                 to at least one repository in the workspace             * **owner**: returns a list of workspaces which the caller has administrator access             
  --q: string #  Query string to narrow down the response. See [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering) for details.
  --qp-sort: string #  Name of a response property to sort results. See [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results) for details.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a workspace
#
# GET /workspaces/{workspace}
export def "workspaces get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<avatar: record<href: string, name: string>, html: record<href: string, name: string>, members: record<href: string, name: string>, owners: record<href: string, name: string>, projects: record<href: string, name: string>, repositories: record<href: string, name: string>, snippets: record<href: string, name: string>, self: record<href: string, name: string>>, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhooks for a workspace
#
# GET /workspaces/{workspace}/hooks
export def "workspaces-hooks list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record, active: bool, created_at: string, events: list, secret_set: bool, secret: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook for a workspace
#
# POST /workspaces/{workspace}/hooks
export def "workspaces-hooks post" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record<type: string>, active: bool, created_at: string, events: list<string>, secret_set: bool, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a webhook for a workspace
#
# DELETE /workspaces/{workspace}/hooks/{uid}
export def "workspaces-hooks delete" [
  uid: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/hooks/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook for a workspace
#
# GET /workspaces/{workspace}/hooks/{uid}
export def "workspaces-hooks get" [
  uid: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record<type: string>, active: bool, created_at: string, events: list<string>, secret_set: bool, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/hooks/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook for a workspace
#
# PUT /workspaces/{workspace}/hooks/{uid}
export def "workspaces-hooks put" [
  uid: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, url: string, description: string, subject_type: string, subject: record<type: string>, active: bool, created_at: string, events: list<string>, secret_set: bool, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/hooks/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users in a workspace
#
# GET /workspaces/{workspace}/members
export def "workspaces-members list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user membership for a workspace
#
# GET /workspaces/{workspace}/members/{member}
export def "workspaces-members get" [
  member: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, user: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>, workspace: record<type: string, links: record<avatar: record, html: record, members: record, owners: record, projects: record, repositories: record, snippets: record, self: record>, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/members/($member)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user permissions in a workspace
#
# GET /workspaces/{workspace}/permissions
export def "workspaces-permissions get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, user: record, workspace: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all repository permissions for a workspace
#
# GET /workspaces/{workspace}/permissions/repositories
export def "workspaces-permissions-repositories list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, permission: string, user: record, repository: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace)/permissions/repositories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a repository permissions for a workspace
#
# GET /workspaces/{workspace}/permissions/repositories/{repo_slug}
export def "workspaces-permissions-repositories get" [
  repo_slug: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string #  Query string to narrow down the response as per [filtering and sorting](/cloud/bitbucket/rest/intro/#filtering).
  --qp-sort: string #  Name of a response property sort the result by as per [filtering and sorting](/cloud/bitbucket/rest/intro/#sorting-query-results).
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, permission: string, user: record, repository: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace)/permissions/repositories/($repo_slug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get OpenID configuration for OIDC in Pipelines
#
# GET /workspaces/{workspace}/pipelines-config/identity/oidc/.well-known/openid-configuration
# operationId: getOIDCConfiguration
export def "workspaces-pipelines-config-identity-oidc-well-known-openid-configuration get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/identity/oidc/.well-known/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get keys for OIDC in Pipelines
#
# GET /workspaces/{workspace}/pipelines-config/identity/oidc/keys.json
# operationId: getOIDCKeys
export def "workspaces-pipelines-config-identity-oidc-keysjson get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/identity/oidc/keys.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace runners
#
# GET /workspaces/{workspace}/pipelines-config/runners
# operationId: getWorkspaceRunners
export def "workspaces-pipelines-config-runners list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, name: string, labels: list, state: record, created_on: string, updated_on: string, oauth_client: record>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/runners")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create workspace runner
#
# POST /workspaces/{workspace}/pipelines-config/runners
# operationId: createWorkspaceRunner
export def "workspaces-pipelines-config-runners createWorkspaceRunner" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, name: string, labels: list<string>, state: record<type: string, status: string, version: record<type: string, version: string, current: string>, updated_on: string, cordoned: bool>, created_on: string, updated_on: string, oauth_client: record<type: string, id: string, secret: string, token_endpoint: string, audience: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/runners")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get workspace runner
#
# GET /workspaces/{workspace}/pipelines-config/runners/{runner_uuid}
# operationId: getWorkspaceRunner
export def "workspaces-pipelines-config-runners get" [
  workspace: string
  runner_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, name: string, labels: list<string>, state: record<type: string, status: string, version: record<type: string, version: string, current: string>, updated_on: string, cordoned: bool>, created_on: string, updated_on: string, oauth_client: record<type: string, id: string, secret: string, token_endpoint: string, audience: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/runners/($runner_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workspace runner
#
# PUT /workspaces/{workspace}/pipelines-config/runners/{runner_uuid}
# operationId: updateWorkspaceRunner
export def "workspaces-pipelines-config-runners updateWorkspaceRunner" [
  workspace: string
  runner_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, name: string, labels: list<string>, state: record<type: string, status: string, version: record<type: string, version: string, current: string>, updated_on: string, cordoned: bool>, created_on: string, updated_on: string, oauth_client: record<type: string, id: string, secret: string, token_endpoint: string, audience: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/runners/($runner_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete workspace runner
#
# DELETE /workspaces/{workspace}/pipelines-config/runners/{runner_uuid}
# operationId: deleteWorkspaceRunner
export def "workspaces-pipelines-config-runners delete" [
  workspace: string
  runner_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/runners/($runner_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List variables for a workspace
#
# GET /workspaces/{workspace}/pipelines-config/variables
# operationId: getPipelineVariablesForWorkspace
export def "workspaces-pipelines-config-variables list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<page: int, values: table<type: string, uuid: string, key: string, value: string, secured: bool>, size: int, pagelen: int, next: string, previous: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/variables")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a variable for a workspace
#
# POST /workspaces/{workspace}/pipelines-config/variables
# operationId: createPipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables createPipelineVariableForWorkspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/variables")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get variable for a workspace
#
# GET /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# operationId: getPipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables get" [
  workspace: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update variable for a workspace
#
# PUT /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# operationId: updatePipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables updatePipelineVariableForWorkspace" [
  workspace: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --uuid: string # The UUID identifying the variable.
  --key: string # The unique name of the variable.
  --value: string # The value of the variable. If the variable is secured, this will be empty.
  --secured: oneof<nothing, bool> # If true, this variable will be treated as secured. The value will never be exposed in the logs or the REST API.
]: any -> record<type: string, uuid: string, key: string, value: string, secured: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/variables/($variable_uuid)")
  let body = {type: $type, uuid: $uuid, key: $key, value: $value, secured: $secured} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a variable for a workspace
#
# DELETE /workspaces/{workspace}/pipelines-config/variables/{variable_uuid}
# operationId: deletePipelineVariableForWorkspace
export def "workspaces-pipelines-config-variables delete" [
  workspace: string
  variable_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/pipelines-config/variables/($variable_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List projects in a workspace
#
# GET /workspaces/{workspace}/projects
export def "workspaces-projects list" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, uuid: string, key: string, owner: record, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a project in a workspace
#
# POST /workspaces/{workspace}/projects
# --links shape: {html?: record, avatar?: record}
export def "workspaces-projects post" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {html?: record, avatar?: record}
  --uuid: string # The project's immutable id.
  --key: string # The project's key.
  --owner: any
  --name: string # The name of the project.
  --description: string
  --is-private: oneof<nothing, bool> #  Indicates whether the project is publicly accessible, or whether it is private to the team and consequently only visible to team members. Note that private projects cannot contain public repositories.
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --has-publicly-visible-repos: oneof<nothing, bool> #  Indicates whether the project contains publicly visible repositories. Note that private projects cannot contain public repositories.
]: any -> record<type: string, links: record<html: record<href: string, name: string>, avatar: record<href: string, name: string>>, uuid: string, key: string, owner: record<links: record<avatar: record, self: record, html: record, members: record, projects: record, repositories: record>>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects")
  let body = {type: $type, links: $links, uuid: $uuid, key: $key, owner: $owner, name: $name, description: $description, is_private: $is_private, created_on: $created_on, updated_on: $updated_on, has_publicly_visible_repos: $has_publicly_visible_repos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a project for a workspace
#
# DELETE /workspaces/{workspace}/projects/{project_key}
export def "workspaces-projects delete" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a project for a workspace
#
# GET /workspaces/{workspace}/projects/{project_key}
export def "workspaces-projects get" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<html: record<href: string, name: string>, avatar: record<href: string, name: string>>, uuid: string, key: string, owner: record<links: record<avatar: record, self: record, html: record, members: record, projects: record, repositories: record>>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project for a workspace
#
# PUT /workspaces/{workspace}/projects/{project_key}
# --links shape: {html?: record, avatar?: record}
export def "workspaces-projects put" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string
  --links: record # shape: {html?: record, avatar?: record}
  --uuid: string # The project's immutable id.
  --key: string # The project's key.
  --owner: any
  --name: string # The name of the project.
  --description: string
  --is-private: oneof<nothing, bool> #  Indicates whether the project is publicly accessible, or whether it is private to the team and consequently only visible to team members. Note that private projects cannot contain public repositories.
  --created-on: string # format: date-time
  --updated-on: string # format: date-time
  --has-publicly-visible-repos: oneof<nothing, bool> #  Indicates whether the project contains publicly visible repositories. Note that private projects cannot contain public repositories.
]: any -> record<type: string, links: record<html: record<href: string, name: string>, avatar: record<href: string, name: string>>, uuid: string, key: string, owner: record<links: record<avatar: record, self: record, html: record, members: record, projects: record, repositories: record>>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)")
  let body = {type: $type, links: $links, uuid: $uuid, key: $key, owner: $owner, name: $name, description: $description, is_private: $is_private, created_on: $created_on, updated_on: $updated_on, has_publicly_visible_repos: $has_publicly_visible_repos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the branching model for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/branching-model
export def "workspaces-projects-branching-model get" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, branch_types: table<kind: string, prefix: string>, development: record<name: string, use_mainbranch: bool>, production: record<name: string, use_mainbranch: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/branching-model")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the branching model config for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/branching-model/settings
export def "workspaces-projects-branching-model-settings get" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, production: record<is_valid: bool, name: string, use_mainbranch: bool, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/branching-model/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the branching model config for a project
#
# PUT /workspaces/{workspace}/projects/{project_key}/branching-model/settings
export def "workspaces-projects-branching-model-settings put" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, branch_types: table<enabled: bool, kind: string, prefix: string>, development: record<is_valid: bool, name: string, use_mainbranch: bool>, production: record<is_valid: bool, name: string, use_mainbranch: bool, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/branching-model/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the default reviewers in a project
#
# GET /workspaces/{workspace}/projects/{project_key}/default-reviewers
export def "workspaces-projects-default-reviewers list" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, reviewer_type: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/default-reviewers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove the specific user from the project's default reviewers
#
# DELETE /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
export def "workspaces-projects-default-reviewers delete" [
  project_key: string
  selected_user: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/default-reviewers/($selected_user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a default reviewer
#
# GET /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
export def "workspaces-projects-default-reviewers get" [
  project_key: string
  selected_user: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<links: record<avatar: record<href: string, name: string>, self: record<href: string, name: string>, html: record<href: string, name: string>, repositories: record<href: string, name: string>>, account_id: string, account_status: string, has_2fa_enabled: bool, nickname: string, is_staff: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/default-reviewers/($selected_user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add the specific user as a default reviewer for the project
#
# PUT /workspaces/{workspace}/projects/{project_key}/default-reviewers/{selected_user}
export def "workspaces-projects-default-reviewers put" [
  project_key: string
  selected_user: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<links: record<avatar: record<href: string, name: string>, self: record<href: string, name: string>, html: record<href: string, name: string>, repositories: record<href: string, name: string>>, account_id: string, account_status: string, has_2fa_enabled: bool, nickname: string, is_staff: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/default-reviewers/($selected_user)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List project deploy keys
#
# GET /workspaces/{workspace}/projects/{project_key}/deploy-keys
export def "workspaces-projects-deploy-keys list" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, key: string, project: record, comment: string, label: string, added_on: string, last_used: string, links: record, created_by: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/deploy-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a project deploy key
#
# POST /workspaces/{workspace}/projects/{project_key}/deploy-keys
export def "workspaces-projects-deploy-keys post" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, key: string, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, comment: string, label: string, added_on: string, last_used: string, links: record<self: record<href: string, name: string>>, created_by: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/deploy-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a deploy key from a project
#
# DELETE /workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}
export def "workspaces-projects-deploy-keys delete" [
  key_id: string
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/deploy-keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a project deploy key
#
# GET /workspaces/{workspace}/projects/{project_key}/deploy-keys/{key_id}
export def "workspaces-projects-deploy-keys get" [
  key_id: string
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, key: string, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>, comment: string, label: string, added_on: string, last_used: string, links: record<self: record<href: string, name: string>>, created_by: record<type: string, links: record<avatar: record>, created_on: string, display_name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/deploy-keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List explicit group permissions for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/permissions-config/groups
export def "workspaces-projects-permissions-config-groups list" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, permission: string, group: record, project: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an explicit group permission for a project
#
# DELETE /workspaces/{workspace}/projects/{project_key}/permissions-config/groups/{group_slug}
export def "workspaces-projects-permissions-config-groups delete" [
  group_slug: string
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/groups/($group_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an explicit group permission for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/permissions-config/groups/{group_slug}
export def "workspaces-projects-permissions-config-groups get" [
  group_slug: string
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, permission: string, group: record<type: string, links: record<self: record, html: record>, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, workspace: record<type: string, links: record, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string>, name: string, slug: string, full_slug: string>, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/groups/($group_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an explicit group permission for a project
#
# PUT /workspaces/{workspace}/projects/{project_key}/permissions-config/groups/{group_slug}
export def "workspaces-projects-permissions-config-groups put" [
  group_slug: string
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permission: string@permission-completer-1
]: any -> record<type: string, links: record<self: record<href: string, name: string>>, permission: string, group: record<type: string, links: record<self: record, html: record>, owner: record<type: string, links: record, created_on: string, display_name: string, uuid: string>, workspace: record<type: string, links: record, uuid: string, name: string, slug: string, is_private: bool, is_privacy_enforced: bool, forking_mode: string, created_on: string, updated_on: string>, name: string, slug: string, full_slug: string>, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/groups/($group_slug)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List explicit user permissions for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/permissions-config/users
export def "workspaces-projects-permissions-config-users list" [
  project_key: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, permission: string, user: record, project: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an explicit user permission for a project
#
# DELETE /workspaces/{workspace}/projects/{project_key}/permissions-config/users/{selected_user_id}
export def "workspaces-projects-permissions-config-users delete" [
  project_key: string
  selected_user_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/users/($selected_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an explicit user permission for a project
#
# GET /workspaces/{workspace}/projects/{project_key}/permissions-config/users/{selected_user_id}
export def "workspaces-projects-permissions-config-users get" [
  project_key: string
  selected_user_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, links: record<self: record<href: string, name: string>>, permission: string, user: record<links: record<avatar: record, self: record, html: record, repositories: record>, account_id: string, account_status: string, has_2fa_enabled: bool, nickname: string, is_staff: bool>, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/users/($selected_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an explicit user permission for a project
#
# PUT /workspaces/{workspace}/projects/{project_key}/permissions-config/users/{selected_user_id}
export def "workspaces-projects-permissions-config-users put" [
  project_key: string
  selected_user_id: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permission: string@permission-completer-1
]: any -> record<type: string, links: record<self: record<href: string, name: string>>, permission: string, user: record<links: record<avatar: record, self: record, html: record, repositories: record>, account_id: string, account_status: string, has_2fa_enabled: bool, nickname: string, is_staff: bool>, project: record<type: string, links: record<html: record, avatar: record>, uuid: string, key: string, owner: record<links: record>, name: string, description: string, is_private: bool, created_on: string, updated_on: string, has_publicly_visible_repos: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/projects/($project_key)/permissions-config/users/($selected_user_id)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List workspace pull requests for a user
#
# GET /workspaces/{workspace}/pullrequests/{selected_user}
export def "workspaces-pullrequests get" [
  selected_user: string
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer-2 # Only return pull requests that are in this state. This parameter can be repeated.
]: nothing -> record<size: int, page: int, pagelen: int, next: string, previous: string, values: table<type: string, links: record, id: int, title: string, rendered: record, summary: record, state: string, author: record, source: record, destination: record, merge_commit: record, comment_count: int, task_count: int, close_source_branch: bool, closed_by: record, reason: string, created_on: string, updated_on: string, reviewers: list, participants: list, draft: bool, queued: bool, mergeable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace)/pullrequests/($selected_user)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for code in a workspace
#
# GET /workspaces/{workspace}/search/code
# DEPRECATED
# operationId: searchWorkspace
@deprecated
export def "workspaces-search-code searchWorkspace" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search-query: string # The search query
  --page: int # Which page of the search results to retrieve (format: int32, default: 1)
  --pagelen: int # How many search results to retrieve per page (format: int32, default: 10)
]: nothing -> record<size: int, page: int, pagelen: int, query_substituted: bool, next: string, previous: string, values: table<type: string, content_match_count: int, content_matches: list, path_matches: list, file: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_query" $search_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pagelen" $pagelen "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/workspaces/($workspace)/search/code" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the workspace system GPG public key(s)
#
# GET /workspaces/{workspace}/settings/gpg/public-key
export def "workspaces-settings-gpg-public-key get" [
  workspace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workspaces/($workspace)/settings/gpg/public-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
