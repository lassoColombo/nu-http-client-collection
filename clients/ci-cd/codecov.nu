# Auto-generated client for Codecov API v2.0.0
# Source: https://api.codecov.io/api/v2/schema/
# Auth: --token flag or $env.CODECOV_API_TOKEN

const BASE_URL = "http://localhost/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CODECOV_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def interval-completer [] { ["1d" "30d" "7d"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "users list" } } | get name | first)
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

# Service owners
#
# GET /{service}/
# operationId: root_list
export def "users list" [
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<service: record, username: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Owner detail
#
# GET /{service}/{owner_username}/
# operationId: root_retrieve
export def "users list-1" [
  owner_username: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<service: record, username: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Repository list
#
# GET /{service}/{owner_username}/repos/
# operationId: repos_list
export def "repos list" [
  owner_username: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # whether the repository has received an upload
  --names: list # list of repository names
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, private: bool, updatestamp: string, author: record, language: string, branch: string, active: bool, activated: bool, totals: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "names" $names "multi") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Repository detail
#
# GET /{service}/{owner_username}/repos/{repo_name}/
# operationId: repos_retrieve
export def "repos get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, private: bool, updatestamp: string, author: record<service: record, username: string, name: string>, language: string, branch: string, active: bool, activated: bool, totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Branch list
#
# GET /{service}/{owner_username}/repos/{repo_name}/branches/
# operationId: repos_branches_list
export def "repos-branches list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --author: string
  --ordering: string # Which field to use when ordering the results.
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, updatestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "author" $author "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/branches/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Branch detail
#
# GET /{service}/{owner_username}/repos/{repo_name}/branches/{name}/
# operationId: repos_branches_retrieve
export def "repos-branches get" [
  name: string
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, updatestamp: string, head_commit: record<commitid: string, message: string, timestamp: string, ci_passed: bool, author: record<service: record, username: string, name: string>, branch: string, totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: int>, state: record, parent: string, report: record<totals: record, files: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/branches/($name)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit list
#
# GET /{service}/{owner_username}/repos/{repo_name}/commits/
# operationId: repos_commits_list
export def "repos-commits list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<commitid: string, message: string, timestamp: string, ci_passed: bool, author: record, branch: string, totals: record, state: record, parent: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/commits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit detail
#
# GET /{service}/{owner_username}/repos/{repo_name}/commits/{commitid}/
# operationId: repos_commits_retrieve
export def "repos-commits get" [
  commitid: string
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commitid: string, message: string, timestamp: string, ci_passed: bool, author: record<service: record, username: string, name: string>, branch: string, totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: int>, state: record, parent: string, report: record<totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, files: record<name: string, totals: record, line_coverage: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/commits/($commitid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit uploads
#
# GET /{service}/{owner_username}/repos/{repo_name}/commits/{commitid}/uploads/
# operationId: repos_commits_uploads_list
export def "repos-commits-uploads list" [
  commitid: string
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<created_at: string, updated_at: string, storage_path: string, flags: list, provider: string, build_code: string, name: string, job_code: string, build_url: string, state: string, state_id: int, state_name: any, env: any, upload_type: string, upload_extras: any, totals: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/commits/($commitid)/uploads/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Comparison
#
# GET /{service}/{owner_username}/repos/{repo_name}/compare/
# operationId: repos_compare_retrieve
export def "repos-compare get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-base: string # base commit SHA (`head` also required)
  --head: string # head commit SHA (`base` also required)
  --pullid: int # pull ID on which to perform the comparison (alternative to specifying `base` and `head`)
]: nothing -> record<base_commit: string, head_commit: string, totals: record<base: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, head: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, patch: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>>, commit_uploads: table<commitid: string, message: string, timestamp: string, ci_passed: bool, author: record, branch: string, totals: record, state: record, parent: string>, diff: record, files: list<record>, untracked: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "pullid" $pullid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/compare/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Component comparison
#
# GET /{service}/{owner_username}/repos/{repo_name}/compare/components
# operationId: repos_compare_components_retrieve
export def "repos-compare-components get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-base: string # base commit SHA (`head` also required)
  --head: string # head commit SHA (`base` also required)
  --pullid: int # pull ID on which to perform the comparison (alternative to specifying `base` and `head`)
]: nothing -> record<component_id: string, name: string, base_report_totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, head_report_totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, diff_totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "pullid" $pullid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/compare/components" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# File comparison
#
# GET /{service}/{owner_username}/repos/{repo_name}/compare/file/{file_path}
# operationId: repos_compare_file_retrieve
export def "repos-compare-file get" [
  file_path: string
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-base: string # base commit SHA (`head` also required)
  --head: string # head commit SHA (`base` also required)
  --pullid: int # pull ID on which to perform the comparison (alternative to specifying `base` and `head`)
]: nothing -> record<name: any, totals: record<base: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, head: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, patch: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>>, has_diff: bool, stats: any, change_summary: any, lines: table<value: string, number: any, coverage: any, is_diff: bool, added: bool, removed: bool, sessions: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "pullid" $pullid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/compare/file/($file_path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Flag comparison
#
# GET /{service}/{owner_username}/repos/{repo_name}/compare/flags
# operationId: repos_compare_flags_retrieve
export def "repos-compare-flags get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-base: string # base commit SHA (`head` also required)
  --head: string # head commit SHA (`base` also required)
  --pullid: int # pull ID on which to perform the comparison (alternative to specifying `base` and `head`)
]: nothing -> record<name: string, base_report_totals: record, head_report_totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, diff_totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "pullid" $pullid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/compare/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Impacted files comparison
#
# GET /{service}/{owner_username}/repos/{repo_name}/compare/impacted_files
# operationId: repos_compare_impacted_files_retrieve
export def "repos-compare-impacted-files get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-base: string # base commit SHA (`head` also required)
  --head: string # head commit SHA (`base` also required)
  --pullid: int # pull ID on which to perform the comparison (alternative to specifying `base` and `head`)
]: nothing -> record<base_commit: string, head_commit: string, totals: record<base: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, head: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, patch: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>>, commit_uploads: table<commitid: string, message: string, timestamp: string, ci_passed: bool, author: record, branch: string, totals: record, state: record, parent: string>, diff: record, files: list<record>, untracked: list<string>, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "pullid" $pullid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/compare/impacted_files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Segmented file comparison
#
# GET /{service}/{owner_username}/repos/{repo_name}/compare/segments/{file_path}
# operationId: repos_compare_segments_retrieve
export def "repos-compare-segments get" [
  file_path: string
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-base: string # base commit SHA (`head` also required)
  --head: string # head commit SHA (`base` also required)
  --pullid: int # pull ID on which to perform the comparison (alternative to specifying `base` and `head`)
]: nothing -> record<segments: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base" $qp_base "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "pullid" $pullid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/compare/segments/($file_path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Component list
#
# GET /{service}/{owner_username}/repos/{repo_name}/components/
# operationId: repos_components_list
export def "repos-components list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name for which to return components (of head commit)
  --sha: string # commit SHA for which to return components
]: nothing -> table<component_id: string, name: string, coverage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "sha" $sha "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/components/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Repository config
#
# GET /{service}/{owner_username}/repos/{repo_name}/config/
# operationId: repos_config_retrieve
export def "repos-config get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<upload_token: string, graph_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/config/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coverage trend
#
# GET /{service}/{owner_username}/repos/{repo_name}/coverage/
# operationId: repos_coverage_list
export def "repos-coverage list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name
  --end-date: string # end datetime (inclusive) (format: date-time)
  --interval: string@interval-completer # * `1d` - 1 day * `7d` - 7 day * `30d` - 30 day
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --start-date: string # start datetime (inclusive) (format: date-time)
]: nothing -> record<count: int, next: string, previous: string, results: table<timestamp: string, min: float, max: float, avg: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "start_date" $start_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/coverage/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluation compare
#
# GET /{service}/{owner_username}/repos/{repo_name}/evals/compare/
# operationId: repos_evals_compare_retrieve
export def "repos-evals-compare get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --base-sha: string # base commit SHA to compare from
  --head-sha: string # head commit SHA to compare to
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "base_sha" $base_sha "scalar") (serialize-qp "head_sha" $head_sha "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/evals/compare/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluation summary
#
# GET /{service}/{owner_username}/repos/{repo_name}/evals/summary/
# operationId: repos_evals_summary_retrieve
export def "repos-evals-summary get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --classname: string # class name the test belongs to, or `describe` block in vitest, or run name in langfuse
  --commit: string # commit SHA for which to return evaluation summary
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "classname" $classname "scalar") (serialize-qp "commit" $commit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/evals/summary/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# File coverage report
#
# GET /{service}/{owner_username}/repos/{repo_name}/file_report/{path}/
# operationId: repos_file_report_retrieve
export def "repos-file-report get" [
  owner_username: string
  path: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name for which to return report (of head commit)
  --sha: string # commit SHA for which to return report
]: nothing -> record<name: string, totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, line_coverage: list<any>, commit_sha: string, commit_file_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "sha" $sha "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/file_report/($path)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Flag list
#
# GET /{service}/{owner_username}/repos/{repo_name}/flags/
# operationId: repos_flags_list
export def "repos-flags list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<flag_name: string, coverage: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/flags/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coverage trend
#
# GET /{service}/{owner_username}/repos/{repo_name}/flags/{flag_name}/coverage/
# operationId: repos_flags_coverage_list
export def "repos-flags-coverage list" [
  flag_name: string
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name
  --end-date: string # end datetime (inclusive) (format: date-time)
  --interval: string@interval-completer # * `1d` - 1 day * `7d` - 7 day * `30d` - 30 day
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --start-date: string # start datetime (inclusive) (format: date-time)
]: nothing -> record<count: int, next: string, previous: string, results: table<timestamp: string, min: float, max: float, avg: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "start_date" $start_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/flags/($flag_name)/coverage/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pull list
#
# GET /{service}/{owner_username}/repos/{repo_name}/pulls/
# operationId: repos_pulls_list
export def "repos-pulls list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --start-date: string # only return pulls with updatestamp on or after this date (format: date-time)
  --state: string # the state of the pull (open/merged/closed)
]: nothing -> record<count: int, next: string, previous: string, results: table<pullid: int, title: string, base_totals: record, head_totals: record, updatestamp: string, state: record, ci_passed: bool, author: record, patch: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/pulls/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pull detail
#
# GET /{service}/{owner_username}/repos/{repo_name}/pulls/{pullid}/
# operationId: repos_pulls_retrieve
export def "repos-pulls get" [
  owner_username: string
  pullid: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pullid: int, title: string, base_totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: int>, head_totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: int>, updatestamp: string, state: record, ci_passed: bool, author: record<service: record, username: string, name: string>, patch: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/pulls/($pullid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit coverage report
#
# GET /{service}/{owner_username}/repos/{repo_name}/report/
# operationId: repos_report_retrieve
export def "repos-report get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name for which to return report (of head commit)
  --component-id: string # filter report to only include info pertaining to given component id
  --flag: string # filter report to only include info pertaining to given flag name
  --path: string # filter report to only include file paths starting with this value
  --sha: string # commit SHA for which to return report
]: nothing -> record<totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, files: record<name: string, totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, line_coverage: list<any>>, commit_file_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "component_id" $component_id "scalar") (serialize-qp "flag" $flag "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "sha" $sha "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/report/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coverage report tree
#
# GET /{service}/{owner_username}/repos/{repo_name}/report/tree
# operationId: repos_report_tree_retrieve
export def "repos-report-tree get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name for which to return report (of head commit)
  --component-id: string # filter report to only include info pertaining to given component id
  --depth: string # depth of the traversal (default=1)
  --flag: string # filter report to only include info pertaining to given flag name
  --path: string # starting path of the traversal (default is root path)
  --sha: string # commit SHA for which to return report
]: nothing -> record<name: string, full_path: string, coverage: float, lines: int, hits: int, partials: int, misses: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "component_id" $component_id "scalar") (serialize-qp "depth" $depth "scalar") (serialize-qp "flag" $flag "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "sha" $sha "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/report/tree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test analytics list
#
# GET /{service}/{owner_username}/repos/{repo_name}/test-analytics/
# operationId: repos_test_analytics_list
export def "repos-test-analytics list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Branch name for which to return test analytics
  --commit-sha: string # Commit SHA for which to return test analytics
  --duration-max: int # Maximum duration of the test in seconds
  --duration-min: int # Minimum duration of the test in seconds
  --outcome: string # Status of the test (failure, skip, error, pass)
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<test_id: string, name: string, classname: string, testsuite: string, computed_name: string, outcome: string, duration_seconds: float, failure_message: string, framework: string, filename: string, repo_id: int, commit_sha: string, branch: string, flags: list, upload_id: int, properties: any, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "commit_sha" $commit_sha "scalar") (serialize-qp "duration_max" $duration_max "scalar") (serialize-qp "duration_min" $duration_min "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/test-analytics/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve test results
#
# GET /{service}/{owner_username}/repos/{repo_name}/test-results/
# operationId: repos_test_results_list
export def "repos-test-results list" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Branch name for which to return test results
  --commit-id: string # Commit SHA for which to return test results
  --duration-max: int # Maximum duration of the test in seconds
  --duration-min: int # Minimum duration of the test in seconds
  --outcome: string # Status of the test (failure, skip, error, pass)
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<test_id: string, name: string, classname: string, testsuite: string, computed_name: string, outcome: string, duration_seconds: float, failure_message: string, framework: string, filename: string, repo_id: int, commit_sha: string, branch: string, flags: list, upload_id: int, properties: any, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "commit_id" $commit_id "scalar") (serialize-qp "duration_max" $duration_max "scalar") (serialize-qp "duration_min" $duration_min "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/test-results/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve test results
#
# GET /{service}/{owner_username}/repos/{repo_name}/test-results/{id}/
# operationId: repos_test_results_retrieve
export def "repos-test-results get" [
  id: string
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # Branch name for which to return test results
  --commit-id: string # Commit SHA for which to return test results
  --duration-max: int # Maximum duration of the test in seconds
  --duration-min: int # Minimum duration of the test in seconds
  --outcome: string # Status of the test (failure, skip, error, pass)
]: nothing -> record<test_id: string, name: string, classname: string, testsuite: string, computed_name: string, outcome: string, duration_seconds: float, failure_message: string, framework: string, filename: string, repo_id: int, commit_sha: string, branch: string, flags: list<string>, upload_id: int, properties: any, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "commit_id" $commit_id "scalar") (serialize-qp "duration_max" $duration_max "scalar") (serialize-qp "duration_min" $duration_min "scalar") (serialize-qp "outcome" $outcome "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/test-results/($id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit coverage totals
#
# GET /{service}/{owner_username}/repos/{repo_name}/totals/
# operationId: repos_totals_retrieve
export def "repos-totals get" [
  owner_username: string
  repo_name: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branch: string # branch name for which to return report (of head commit)
  --component-id: string # filter report to only include info pertaining to given component id
  --flag: string # filter report to only include info pertaining to given flag name
  --path: string # filter report to only include file paths starting with this value
  --sha: string # commit SHA for which to return report
]: nothing -> record<totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, files: record<name: string, totals: record<files: int, lines: int, hits: int, misses: int, partials: int, coverage: float, branches: int, methods: int, messages: int, sessions: int, complexity: float, complexity_total: float, complexity_ratio: float, diff: any>, line_coverage: list<any>>, commit_file_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branch" $branch "scalar") (serialize-qp "component_id" $component_id "scalar") (serialize-qp "flag" $flag "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "sha" $sha "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/repos/($repo_name)/totals/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User session list
#
# GET /{service}/{owner_username}/user-sessions/
# operationId: user_sessions_list
export def "user-sessions list" [
  owner_username: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<username: string, name: string, has_active_session: bool, expiry_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/user-sessions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User list
#
# GET /{service}/{owner_username}/users/
# operationId: users_list
export def "users list-2" [
  owner_username: string
  service: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --activated: oneof<nothing, bool>
  --is-admin: oneof<nothing, bool>
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<service: string, username: string, name: string, activated: bool, is_admin: bool, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "activated" $activated "scalar") (serialize-qp "is_admin" $is_admin "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($service)/($owner_username)/users/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User detail
#
# GET /{service}/{owner_username}/users/{user_username_or_ownerid}/
# operationId: users_retrieve
export def "users get" [
  owner_username: string
  service: string
  user_username_or_ownerid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<service: string, username: string, name: string, activated: bool, is_admin: bool, email: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/users/($user_username_or_ownerid)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /{service}/{owner_username}/users/{user_username_or_ownerid}/
# operationId: users_partial_update
export def "users patch" [
  owner_username: string
  service: string
  user_username_or_ownerid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --activated: oneof<nothing, bool>
]: any -> record<service: string, username: string, name: string, activated: bool, is_admin: bool, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($service)/($owner_username)/users/($user_username_or_ownerid)/")
  let body = {activated: $activated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
