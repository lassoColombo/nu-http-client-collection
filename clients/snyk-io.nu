# Auto-generated client for Snyk API v1.0.0
# Source: https://api.apis.guru/v2/specs/snyk.io/1.0.0/openapi.json
# Auth: --token flag or $env.SNYK_API_TOKEN

const BASE_URL = "https://api.snyk.io/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SNYK_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.snyk.io/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-by-completer [] { ["dependenciesWithIssues" "dependency" "projects" "severity"] }
def order-completer [] { ["asc" "desc"] }
def type-completer [] { ["acr" "artifactory-cr" "azure-repos" "bitbucket-cloud" "bitbucket-server" "digitalocean-cr" "docker-hub" "ecr" "gcr" "github" "github-cr" "github-enterprise" "gitlab" "gitlab-cr" "google-artifact-cr" "harbor-cr" "nexus-cr" "quay-cr"] }
def sort-by-completer-1 [] { ["dependencies" "license" "projects" "severity"] }
def reason-type-completer [] { ["not-vulnerable" "temporary-ignore" "wont-fix"] }
def group-by-completer [] { ["fixable" "project,[severity|fixable]" "severity"] }
def group-by-completer-1 [] { ["isPrivate" "issuesPrevented"] }
def sort-by-completer-2 [] { ["introducedDate" "isFixed" "isIgnored" "isPatchable" "isPatched" "isUpgradable" "issueTitle" "priorityScore" "projectName" "severity"] }
def group-by-completer-2 [] { ["issue"] }
def encoding-completer [] { ["base64" "plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "group-audit get-level-logs" } } | get name | first)
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

# Get group level audit logs
#
# POST /group/{groupId}/audit
# operationId: Get group level audit logs
# --filters shape: {email?: string, ... (4 more fields)}
export def "group-audit get-level-logs" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The date you wish to fetch results from, in the format YYYY-MM-DD. Default is 3 months ago. Please note that logs are only available for past 3 months. (e.g. 2019-07-01)
  --qp-to: string # The date you wish to fetch results until, in the format YYYY-MM-DD. Default is today. Please note that logs are only available for past 3 months. (e.g. 2019-07-07)
  --page: float # The page of results to request. Audit logs are returned in page sizes of 100 (e.g. 1)
  --sort-order: string # The sort order of the returned audit logs by date. Values: `ASC`, `DESC`. Default: `DESC`. (e.g. ASC)
  --filters: record # shape: {email?: string, ... (4 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sortOrder" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/audit") $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all members in a group
#
# GET /group/{groupId}/members
# operationId: List all members in a group
export def "group-members list-list" [
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/members"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a member to an organization within a group
#
# POST /group/{groupId}/org/{orgId}/members
# operationId: Add a member to an organization within a group
export def "group-org-members create-to-organization-within" [
  group_id: string
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # The role of the user, "admin" or "collaborator".
  --user-id: string # The id of the user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), org_id: (encode-path-segment $org_id)} | format pattern "/group/{group_id}/org/{org_id}/members"))
  let req_body = {"role": $role, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all organizations in a group
#
# GET /group/{groupId}/orgs
# operationId: List all organizations in a group
export def "group-orgs list-list-organizations" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return (maximum is 100). (default: 100, e.g. 100)
  --page: float # For pagination - offset (from which to start returning results). (e.g. 1)
  --name: string # Only organizations that have a name that **starts with** this value (case insensitive) will be returned. (e.g. my)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/orgs") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all roles in a group
#
# GET /group/{groupId}/roles
# operationId: List all roles in a group
export def "group-roles list-list" [
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/roles"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View group settings
#
# GET /group/{groupId}/settings
# operationId: View group settings
export def "group-settings get-view" [
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/settings"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group settings
#
# PUT /group/{groupId}/settings
# operationId: Update group settings
export def "group-settings update" [
  group_id: string
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
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/settings"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all tags in a group
#
# GET /group/{groupId}/tags
# operationId: List all tags in a group
export def "group-tags list-list" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return (the default is 1000). (e.g. 10)
  --page: float # The offset from which to start returning results from. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/tags") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete tag from group
#
# POST /group/{groupId}/tags/delete
# operationId: Delete tag from group
export def "group-tags-delete delete" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # force delete tag that has entities (default is `false`).
  --key: string # Valid tag key.
  --value: string # Valid tag value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/group/{group_id}/tags/delete"))
  let req_body = {"force": $force, "key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Monitor Dep Graph
#
# POST /monitor/dep-graph
# operationId: Monitor Dep Graph
# --depGraph shape: {graph: record, pkgManager: record, pkgs: list, schemaVersion: string}
# --meta shape: {targetFramework?: string}
export def "monitor-dep-graph create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  dep_graph: record # A [DepGraph data object](https://github.com/snyk/dep-graph#depgraphdata) defining all packages and their relationships. — shape: {graph: record, pkgManager: record, pkgs: list, schemaVersion: string}
  --meta: record # Project metadata — shape: {targetFramework?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/monitor/dep-graph" $qp)
  let req_body = {"depGraph": $dep_graph, "meta": $meta} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a new organization
#
# POST /org
# operationId: Create a new organization
export def "org create-new-organization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-id: string # The group ID. The `API_KEY` must have access to this group.
  name: string # The name of the new organization
  --source-org-id: string # The id of an organization to copy settings from. If provided, this organization must be associated with the same group. The items that will be copied are: Source control integrations (GitHub, GitLab, BitBucket) \+ Container registries integrations (ACR, Docker Hub, ECR, GCR) \+ Container orchestrators integrations (Kubernetes) \+ PaaS and Serverless Integrations (Heroku, AWS Lambda) \+ Notification integrations (Slack, Jira) \+ Policies \+ Ignore settings \+ Language settings \+ Infrastructure as Code settings \+ Snyk Code settings The following will not be copied across: Service accounts \+ Members \+ Projects \+ Notification preferences
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org")
  let req_body = {"groupId": $group_id, "name": $name, "sourceOrgId": $source_org_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove organization
#
# DELETE /org/{orgId}
# operationId: Remove organization
export def "org delete-organization" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organization level audit logs
#
# POST /org/{orgId}/audit
# operationId: Get organization level audit logs
# --filters shape: {email?: string, ... (4 more fields)}
export def "org-audit get-organization-level-logs" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The date you wish to fetch results from, in the format YYYY-MM-DD. Default is 3 months ago. Please note that logs are only available for past 3 months. (e.g. 2019-07-01)
  --qp-to: string # The date you wish to fetch results until, in the format YYYY-MM-DD. Default is today. Please note that logs are only available for past 3 months. (e.g. 2019-07-07)
  --page: float # The page of results to request. Audit logs are returned in page sizes of 100. (e.g. 1)
  --sort-order: string # The sort order of the returned audit logs by date. Values: `ASC`, `DESC`. Default: `DESC`. (e.g. ASC)
  --filters: record # shape: {email?: string, ... (4 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sortOrder" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/audit") $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all dependencies
#
# POST /org/{orgId}/dependencies
# operationId: List all dependencies
# --filters shape: {depStatus?: string, dependencies?: any, languages?: list, licenses?: any, projects?: any, severity?: list}
export def "org-dependencies list-list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer # The field to sort results by. (default: dependency, e.g. dependency)
  --order: string@order-completer # The direction to sort results by. (default: asc)
  --page: float # The page of results to fetch. (default: 1)
  --per-page: float # The number of results to fetch per page (maximum is 1000). (default: 20)
  --filters: record # shape: {depStatus?: string, dependencies?: any, languages?: list, licenses?: any, projects?: any, severity?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/dependencies") $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get an organization's entitlement value
#
# GET /org/{orgId}/entitlement/{entitlementKey}
# operationId: Get an organization's entitlement value
export def "org-entitlement get-organizations-value" [
  org_id: string
  entitlement_key: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), entitlement_key: (encode-path-segment $entitlement_key)} | format pattern "/org/{org_id}/entitlement/{entitlement_key}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all entitlements
#
# GET /org/{orgId}/entitlements
# operationId: List all entitlements
export def "org-entitlements list-list" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/entitlements"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /org/{orgId}/integrations
# operationId: List
export def "org-integrations list" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/integrations"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new integration
#
# POST /org/{orgId}/integrations
# operationId: Add new integration
# --credentials shape: {AcrCredentials?: record, ArtifactoryCrCredentials?: record, AzureReposCredentials?: record, BitbucketCloudCredentials?: record, BitbucketServerCredentials?: record, DigitalOceanCrCredentials?: record, DockerHubCredentials?: record, EcrCredentials?: record, GcrCredentials?: record, GitHubCredentials?: record, GitHubCrCredentials?: record, GitHubEnterpriseCredentials?: record, GitLabCredentials?: record, GitLabCrCredentials?: record, GoogleArtifactCrCredentials?: record, ... (3 more fields)}
# --broker shape: {enabled?: bool}
export def "org-integrations create-new" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --credentials: record # credentials for given integration — shape: {AcrCredentials?: record, ArtifactoryCrCredentials?: record, AzureReposCredentials?: record, BitbucketCloudCredentials?: record, BitbucketServerCredentials?: record, DigitalOceanCrCredentials?: record, DockerHubCredentials?: record, EcrCredentials?: record, GcrCredentials?: record, GitHubCredentials?: record, GitHubCrCredentials?: record, GitHubEnterpriseCredentials?: record, GitLabCredentials?: record, GitLabCrCredentials?: record, GoogleArtifactCrCredentials?: record, ... (3 more fields)}
  --type: string@type-completer # integration type
  --broker: record # brokered integration settings — shape: {enabled?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/integrations"))
  let req_body = {"credentials": $credentials, "type": $type, "broker": $broker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update existing integration
#
# PUT /org/{orgId}/integrations/{integrationId}
# operationId: Update existing integration
# --broker shape: {enabled?: bool}
# --credentials shape: {AcrCredentials?: record, ArtifactoryCrCredentials?: record, AzureReposCredentials?: record, BitbucketCloudCredentials?: record, BitbucketServerCredentials?: record, DigitalOceanCrCredentials?: record, DockerHubCredentials?: record, EcrCredentials?: record, GcrCredentials?: record, GitHubCredentials?: record, GitHubCrCredentials?: record, GitHubEnterpriseCredentials?: record, GitLabCredentials?: record, GitLabCrCredentials?: record, GoogleArtifactCrCredentials?: record, ... (3 more fields)}
export def "org-integrations update-existing" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --broker: record # brokered integration settings — shape: {enabled?: bool}
  --type: string@type-completer # integration type
  --credentials: record # credentials for given integration — shape: {AcrCredentials?: record, ArtifactoryCrCredentials?: record, AzureReposCredentials?: record, BitbucketCloudCredentials?: record, BitbucketServerCredentials?: record, DigitalOceanCrCredentials?: record, DockerHubCredentials?: record, EcrCredentials?: record, GcrCredentials?: record, GitHubCredentials?: record, GitHubCrCredentials?: record, GitHubEnterpriseCredentials?: record, GitLabCredentials?: record, GitLabCrCredentials?: record, GoogleArtifactCrCredentials?: record, ... (3 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}"))
  let req_body = {"broker": $broker, "type": $type, "credentials": $credentials} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete credentials
#
# DELETE /org/{orgId}/integrations/{integrationId}/authentication
# operationId: Delete credentials
export def "org-integrations-authentication delete-credentials" [
  org_id: string
  integration_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/authentication"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provision new broker token
#
# POST /org/{orgId}/integrations/{integrationId}/authentication/provision-token
# operationId: Provision new broker token
export def "org-integrations-authentication-provision-token create-new-broker" [
  org_id: string
  integration_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/authentication/provision-token"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Switch between broker tokens
#
# POST /org/{orgId}/integrations/{integrationId}/authentication/switch-token
# operationId: Switch between broker tokens
export def "org-integrations-authentication-switch-token create-between-broker" [
  org_id: string
  integration_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/authentication/switch-token"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clone an integration (with settings and credentials)
#
# POST /org/{orgId}/integrations/{integrationId}/clone
# operationId: Clone an integration (with settings and credentials)
export def "org-integrations-clone clone-with-settings-and-credentials" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_org_public_id: string # The organization public ID. The `API_KEY` must have access to this organization.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/clone"))
  let req_body = {"destinationOrgPublicId": $destination_org_public_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Import targets
#
# POST /org/{orgId}/integrations/{integrationId}/import
# operationId: Import targets
# --target shape: {branch: string, name: string, owner: string}
export def "org-integrations-import import-targets" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclusion-globs: string # a comma-separated list of up to 10 folder names to exclude from scanning (each folder name must not exceed 100 characters). If not specified, it will default to "fixtures, tests, \_\_tests\_\_, node_modules". If an empty string is provided - no folders will be excluded. This attribute is only respected with Open Source and Container scan targets.
  --files: list # an array of file objects
  --target: record # shape: {branch: string, name: string, owner: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/import"))
  let req_body = {"exclusionGlobs": $exclusion_globs, "files": $files, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get import job details
#
# GET /org/{orgId}/integrations/{integrationId}/import/{jobId}
# operationId: Get import job details
export def "org-integrations-import get-job-details" [
  org_id: string
  integration_id: string
  job_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id), job_id: (encode-path-segment $job_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/import/{job_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve
#
# GET /org/{orgId}/integrations/{integrationId}/settings
# operationId: Retrieve
export def "org-integrations-settings get" [
  org_id: string
  integration_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/settings"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /org/{orgId}/integrations/{integrationId}/settings
# operationId: Update
# --autoRemediationPrs shape: {backlogPrsEnabled?: bool, freshPrsEnabled?: bool, usePatchRemediation?: bool}
# --manualRemediationPrs shape: {usePatchRemediation?: bool}
# --pullRequestAssignment shape: {assignees?: list, enabled?: bool, type?: "auto"|"manual"}
export def "org-integrations-settings update" [
  org_id: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-dep-upgrade-enabled: oneof<nothing, bool> # Defines if the functionality is enabled
  --auto-dep-upgrade-ignored-dependencies: list # A list of strings defining what dependencies should be ignored
  --auto-dep-upgrade-limit: float # A limit on how many automatic dependency upgrade PRs can be opened simultaneously
  --auto-dep-upgrade-min-age: float # The age (in days) that an automatic dependency check is valid for
  --auto-remediation-prs: record # Defines automatic remediation policies — shape: {backlogPrsEnabled?: bool, freshPrsEnabled?: bool, usePatchRemediation?: bool}
  --dockerfile-scm-enabled: oneof<nothing, bool> # If true, will automatically detect and scan Dockerfiles in your Git repositories, surface base image vulnerabilities and recommend possible fixes
  --manual-remediation-prs: record # Defines manual remediation policies — shape: {usePatchRemediation?: bool}
  --pull-request-assignment: record # assign Snyk pull requests — shape: {assignees?: list, enabled?: bool, type?: "auto"|"manual"}
  --pull-request-fail-on-any-vulns: oneof<nothing, bool> # If an opened PR should fail to be validated if any vulnerable dependencies have been detected
  --pull-request-fail-only-for-high-severity: oneof<nothing, bool> # If an opened PR only should fail its validation if any dependencies are marked as being of high severity
  --pull-request-test-enabled: oneof<nothing, bool> # If opened PRs should be tested
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), integration_id: (encode-path-segment $integration_id)} | format pattern "/org/{org_id}/integrations/{integration_id}/settings"))
  let req_body = {"autoDepUpgradeEnabled": $auto_dep_upgrade_enabled, "autoDepUpgradeIgnoredDependencies": $auto_dep_upgrade_ignored_dependencies, "autoDepUpgradeLimit": $auto_dep_upgrade_limit, "autoDepUpgradeMinAge": $auto_dep_upgrade_min_age, "autoRemediationPrs": $auto_remediation_prs, "dockerfileSCMEnabled": $dockerfile_scm_enabled, "manualRemediationPrs": $manual_remediation_prs, "pullRequestAssignment": $pull_request_assignment, "pullRequestFailOnAnyVulns": $pull_request_fail_on_any_vulns, "pullRequestFailOnlyForHighSeverity": $pull_request_fail_only_for_high_severity, "pullRequestTestEnabled": $pull_request_test_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get existing integration by type
#
# GET /org/{orgId}/integrations/{type}
# operationId: Get existing integration by type
export def "org-integrations get-existing" [
  org_id: string
  type: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), type: (encode-path-segment $type)} | format pattern "/org/{org_id}/integrations/{type}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite users
#
# POST /org/{orgId}/invite
# operationId: Invite users
export def "org-invite create-users" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the user.
  --is-admin: oneof<nothing, bool> # (optional) Set the role as admin.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/invite"))
  let req_body = {"email": $email, "isAdmin": $is_admin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all licenses
#
# POST /org/{orgId}/licenses
# operationId: List all licenses
# --filters shape: {dependencies?: any, languages?: list, licenses?: any, projects?: any, severity?: list}
export def "org-licenses list-list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer-1 # The field to sort results by. (default: license, e.g. license)
  --order: string@order-completer # The direction to sort results by. (default: asc)
  --filters: record # shape: {dependencies?: any, languages?: list, licenses?: any, projects?: any, severity?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/licenses") $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Members
#
# GET /org/{orgId}/members
# operationId: List Members
export def "org-members list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-group-admins: oneof<nothing, bool> # Include group administrators who also have access to this organization. (default: false, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGroupAdmins" $include_group_admins "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/members") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a member's role in the organization
#
# PUT /org/{orgId}/members/update/{userId}
# operationId: Update a member's role in the organization
export def "org-members-update update-members-role-in-organization" [
  org_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role-public-id: string # The new role public ID to update the user to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), user_id: (encode-path-segment $user_id)} | format pattern "/org/{org_id}/members/update/{user_id}"))
  let req_body = {"rolePublicId": $role_public_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove a member from the organization
#
# DELETE /org/{orgId}/members/{userId}
# operationId: Remove a member from the organization
export def "org-members delete-from-organization" [
  org_id: string
  user_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), user_id: (encode-path-segment $user_id)} | format pattern "/org/{org_id}/members/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a member in the organization
#
# PUT /org/{orgId}/members/{userId}
# operationId: Update a member in the organization
export def "org-members update-in-organization" [
  org_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # The new role of the user, "admin" or "collaborator".
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), user_id: (encode-path-segment $user_id)} | format pattern "/org/{org_id}/members/{user_id}"))
  let req_body = {"role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get organization notification settings
#
# GET /org/{orgId}/notification-settings
export def "org-notification-settings get" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/notification-settings"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set notification settings
#
# PUT /org/{orgId}/notification-settings
# operationId: Set notification settings
# --new-issues-remediations shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
# --project-imported shape: {enabled: bool}
# --test-limit shape: {enabled: bool}
# --weekly-report shape: {enabled: bool}
export def "org-notification-settings update" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-issues-remediations: record # shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
  --project-imported: record # shape: {enabled: bool}
  --test-limit: record # shape: {enabled: bool}
  --weekly-report: record # shape: {enabled: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/notification-settings"))
  let req_body = {"new-issues-remediations": $new_issues_remediations, "project-imported": $project_imported, "test-limit": $test_limit, "weekly-report": $weekly_report} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a project
#
# DELETE /org/{orgId}/project/{projectId}
# operationId: Delete a project
export def "org-project delete" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single project
#
# GET /org/{orgId}/project/{projectId}
# operationId: Retrieve a single project
export def "org-project get-single" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a project
#
# PUT /org/{orgId}/project/{projectId}
# operationId: Update a project
# --owner shape: {id?: string}
export def "org-project update" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # The branch that this project should be monitoring
  --owner: record # Set to `null` to remove all ownership. User must be a member of the same organization as the project. — shape: {id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}"))
  let req_body = {"branch": $branch, "owner": $owner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Activate
#
# POST /org/{orgId}/project/{projectId}/activate
# operationId: Activate
export def "org-project-activate create" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/activate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Aggregated issues
#
# POST /org/{orgId}/project/{projectId}/aggregated-issues
# operationId: List all Aggregated issues
# --filters shape: {exploitMaturity?: list, ignored?: bool, patched?: bool, priority?: record, severities?: list, types?: list}
export def "org-project-aggregated-issues list-list" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {exploitMaturity?: list, ignored?: bool, patched?: bool, priority?: record, severities?: list, types?: list}
  --include-description: oneof<nothing, bool> # If set to `true`, Include issue's description, if set to `false` (by default), it won't (Non-IaC projects only)
  --include-introduced-through: oneof<nothing, bool> # If set to `true`, Include issue's introducedThrough, if set to `false` (by default), it won't. It's for container only projects (Non-IaC projects only)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/aggregated-issues"))
  let req_body = {"filters": $filters, "includeDescription": $include_description, "includeIntroducedThrough": $include_introduced_through} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Applying attributes
#
# POST /org/{orgId}/project/{projectId}/attributes
# operationId: Applying attributes
export def "org-project-attributes create-applying" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --criticality: list
  --environment: list
  --lifecycle: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/attributes"))
  let req_body = {"criticality": $criticality, "environment": $environment, "lifecycle": $lifecycle} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deactivate
#
# POST /org/{orgId}/project/{projectId}/deactivate
# operationId: Deactivate
export def "org-project-deactivate create" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/deactivate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Project dependency graph
#
# GET /org/{orgId}/project/{projectId}/dep-graph
# operationId: Get Project dependency graph
export def "org-project-dep-graph get-dependency" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/dep-graph"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all project snapshots
#
# POST /org/{orgId}/project/{projectId}/history
# operationId: List all project snapshots
# --filters shape: {imageId?: string}
export def "org-project-history list-list-snapshots" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return (the default is 10, the maximum is 100). (e.g. 10)
  --page: float # The offset from which to start returning results from. (e.g. 1)
  --filters: record # shape: {imageId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/history") $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all project snapshot aggregated issues
#
# POST /org/{orgId}/project/{projectId}/history/{snapshotId}/aggregated-issues
# operationId: List all project snapshot aggregated issues
# --filters shape: {exploitMaturity?: list, ignored?: bool, patched?: bool, priority?: record, severities?: list, types?: list}
export def "org-project-history-aggregated-issues list-list-snapshot" [
  org_id: string
  project_id: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {exploitMaturity?: list, ignored?: bool, patched?: bool, priority?: record, severities?: list, types?: list}
  --include-description: oneof<nothing, bool> # If set to `true`, Include issue's description, if set to `false` (by default), it won't (Non-IaC projects only)
  --include-introduced-through: oneof<nothing, bool> # If set to `true`, Include issue's introducedThrough, if set to `false` (by default), it won't. It's for container only projects (Non-IaC projects only)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/org/{org_id}/project/{project_id}/history/{snapshot_id}/aggregated-issues"))
  let req_body = {"filters": $filters, "includeDescription": $include_description, "includeIntroducedThrough": $include_introduced_through} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all project snapshot issue paths
#
# GET /org/{orgId}/project/{projectId}/history/{snapshotId}/issue/{issueId}/paths
# operationId: List all project snapshot issue paths
export def "org-project-history-issue-paths list-list-snapshot" [
  org_id: string
  project_id: string
  snapshot_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: float # The number of results to return per page (1 - 1000, inclusive). (default: 100, e.g. 3)
  --page: float # The page of results to return. (default: 1, e.g. 2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), snapshot_id: (encode-path-segment $snapshot_id), issue_id: (encode-path-segment $issue_id)} | format pattern "/org/{org_id}/project/{project_id}/history/{snapshot_id}/issue/{issue_id}/paths") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete ignores
#
# DELETE /org/{orgId}/project/{projectId}/ignore/{issueId}
# operationId: Delete ignores
export def "org-project-ignore delete" [
  org_id: string
  project_id: string
  issue_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), issue_id: (encode-path-segment $issue_id)} | format pattern "/org/{org_id}/project/{project_id}/ignore/{issue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve ignore
#
# GET /org/{orgId}/project/{projectId}/ignore/{issueId}
# operationId: Retrieve ignore
export def "org-project-ignore get" [
  org_id: string
  project_id: string
  issue_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), issue_id: (encode-path-segment $issue_id)} | format pattern "/org/{org_id}/project/{project_id}/ignore/{issue_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add ignore
#
# POST /org/{orgId}/project/{projectId}/ignore/{issueId}
# operationId: Add ignore
export def "org-project-ignore create" [
  org_id: string
  project_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disregard-if-fixable: oneof<nothing, bool> # Only ignore the issue if no upgrade or patch is available.
  --expires: string # The timestamp that the issue will no longer be ignored.
  --ignore-path: string # The path to ignore (default is `*` which represents all paths).
  --reason: string # The reason that the issue was ignored.
  reason_type: string@reason-type-completer # The classification of the ignore.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), issue_id: (encode-path-segment $issue_id)} | format pattern "/org/{org_id}/project/{project_id}/ignore/{issue_id}"))
  let req_body = {"disregardIfFixable": $disregard_if_fixable, "expires": $expires, "ignorePath": $ignore_path, "reason": $reason, "reasonType": $reason_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Replace ignores
#
# PUT /org/{orgId}/project/{projectId}/ignore/{issueId}
# operationId: Replace ignores
export def "org-project-ignore update" [
  org_id: string
  project_id: string
  issue_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), issue_id: (encode-path-segment $issue_id)} | format pattern "/org/{org_id}/project/{project_id}/ignore/{issue_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all ignores
#
# GET /org/{orgId}/project/{projectId}/ignores
# operationId: List all ignores
export def "org-project-ignores list-list" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/ignores"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create jira issue
#
# POST /org/{orgId}/project/{projectId}/issue/{issueId}/jira-issue
# operationId: Create jira issue
# --fields shape: {issuetype?: record, project?: record, summary?: string}
export def "org-project-issue-jira-issue create" [
  org_id: string
  project_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: record # shape: {issuetype?: record, project?: record, summary?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), issue_id: (encode-path-segment $issue_id)} | format pattern "/org/{org_id}/project/{project_id}/issue/{issue_id}/jira-issue"))
  let req_body = {"fields": $fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all project issue paths
#
# GET /org/{orgId}/project/{projectId}/issue/{issueId}/paths
# operationId: List all project issue paths
export def "org-project-issue-paths list-list" [
  org_id: string
  project_id: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --snapshot-id: string # The project snapshot ID for which to return issue paths. If set to `latest`, the most recent snapshot will be used. Use the "List all project snapshots" endpoint to find suitable values for this. (default: latest, e.g. 6d5813be-7e6d-4ab8-80c2-1e3e2a454553)
  --per-page: float # The number of results to return per page (1 - 1000, inclusive). (default: 100, e.g. 3)
  --page: float # The page of results to return. (default: 1, e.g. 2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "snapshotId" $snapshot_id "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id), issue_id: (encode-path-segment $issue_id)} | format pattern "/org/{org_id}/project/{project_id}/issue/{issue_id}/paths") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all jira issues
#
# GET /org/{orgId}/project/{projectId}/jira-issues
# operationId: List all jira issues
export def "org-project-jira-issues list-list" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/jira-issues"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move project to a different organization
#
# PUT /org/{orgId}/project/{projectId}/move
# operationId: Move project to a different organization
export def "org-project-move move-to-different-organization" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-org-id: string # The ID of the organization that the project should be moved to. The API_KEY must have group admin permissions. If the project is moved to a new group, a personal level API key is needed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/move"))
  let req_body = {"targetOrgId": $target_org_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete project settings
#
# DELETE /org/{orgId}/project/{projectId}/settings
# operationId: Delete project settings
export def "org-project-settings delete" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List project settings
#
# GET /org/{orgId}/project/{projectId}/settings
# operationId: List project settings
export def "org-project-settings list" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/settings"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project settings
#
# PUT /org/{orgId}/project/{projectId}/settings
# operationId: Update project settings
# --autoRemediationPrs shape: {backlogPrsEnabled?: bool, freshPrsEnabled?: bool, usePatchRemediation?: bool}
# --pullRequestAssignment shape: {assignees?: list, enabled?: bool, type?: "auto"|"manual"}
export def "org-project-settings update" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-dep-upgrade-enabled: oneof<nothing, bool> # If set to `true`, Snyk will raise dependency upgrade PRs automatically.
  --auto-dep-upgrade-ignored-dependencies: list # An array of comma-separated strings with names of dependencies you wish Snyk to ignore to upgrade.
  --auto-dep-upgrade-limit: float # The limit on auto dependency upgrade PRs.
  --auto-dep-upgrade-min-age: float # The age (in days) that an automatic dependency check is valid for
  --auto-remediation-prs: record # Defines automatic remediation policies — shape: {backlogPrsEnabled?: bool, freshPrsEnabled?: bool, usePatchRemediation?: bool}
  --pull-request-assignment: record # assign Snyk pull requests — shape: {assignees?: list, enabled?: bool, type?: "auto"|"manual"}
  --pull-request-fail-on-any-vulns: oneof<nothing, bool> # If set to `true`, fail Snyk Test if the repo has any vulnerabilities. Otherwise, fail only when the PR is adding a vulnerable dependency.
  --pull-request-fail-only-for-high-severity: oneof<nothing, bool> # If set to `true`, fail Snyk Test only for high and critical severity vulnerabilities
  --pull-request-test-enabled: oneof<nothing, bool> # If set to `true`, Snyk Test checks PRs for vulnerabilities.:cq
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/settings"))
  let req_body = {"autoDepUpgradeEnabled": $auto_dep_upgrade_enabled, "autoDepUpgradeIgnoredDependencies": $auto_dep_upgrade_ignored_dependencies, "autoDepUpgradeLimit": $auto_dep_upgrade_limit, "autoDepUpgradeMinAge": $auto_dep_upgrade_min_age, "autoRemediationPrs": $auto_remediation_prs, "pullRequestAssignment": $pull_request_assignment, "pullRequestFailOnAnyVulns": $pull_request_fail_on_any_vulns, "pullRequestFailOnlyForHighSeverity": $pull_request_fail_only_for_high_severity, "pullRequestTestEnabled": $pull_request_test_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add a tag to a project
#
# POST /org/{orgId}/project/{projectId}/tags
# operationId: Add a tag to a project
export def "org-project-tags create" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Alphanumeric including - and _ with a limit of 30 characters
  --value: string # Alphanumeric including - and _ with a limit of 50 characters
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/tags"))
  let req_body = {"key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove a tag from a project
#
# POST /org/{orgId}/project/{projectId}/tags/remove
# operationId: Remove a tag from a project
export def "org-project-tags-remove delete" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # Alphanumeric including - and _ with a limit of 30 characters
  --value: string # Alphanumeric including - and _ with a limit of 50 characters
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/org/{org_id}/project/{project_id}/tags/remove"))
  let req_body = {"key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all projects
#
# POST /org/{orgId}/projects
# operationId: List all projects
# --filters shape: {attributes?: record, isMonitored?: bool, name?: string, origin?: string, tags?: record, type?: string}
export def "org-projects list-list" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {attributes?: record, isMonitored?: bool, name?: string, origin?: string, tags?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/projects"))
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete pending user provision
#
# DELETE /org/{orgId}/provision
# operationId: Delete pending user provision
export def "org-provision delete-pending-user" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/provision"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pending user provisions
#
# GET /org/{orgId}/provision
# operationId: List pending user provisions
export def "org-provision list-pending-user" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/provision"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provision a user to the organization
#
# POST /org/{orgId}/provision
# operationId: Provision a user to the organization
export def "org-provision create-user-to-organization" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email of the user.
  --role: string # Deprecated. Name of the role to grant this user. Must be one of `ADMIN`, `COLLABORATOR`, or `RESTRICTED_COLLABORATOR`. This field is invalid if `rolePublicId` is supplied with the request.
  --role-public-id: string # ID of the role to grant this user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/provision"))
  let req_body = {"email": $email, "role": $role, "rolePublicId": $role_public_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# View organization settings
#
# GET /org/{orgId}/settings
# operationId: View organization settings
export def "org-settings get-view-organization" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/settings"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization settings
#
# PUT /org/{orgId}/settings
# operationId: Update organization settings
# --requestAccess shape: {enabled: bool}
export def "org-settings update-organization" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --request-access: record # Can only be updated if `API_KEY` has edit access to request access settings. — shape: {enabled: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/settings"))
  let req_body = {"requestAccess": $request_access} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List webhooks
#
# GET /org/{orgId}/webhooks
# operationId: List webhooks
export def "org-webhooks list" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/webhooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /org/{orgId}/webhooks
# operationId: Create a webhook
export def "org-webhooks create" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret: string # This is a password you create, that Snyk uses to sign our transports to you, so you be sure the notification is authentic. Your `secret` should: Be a random string with high entropy; Not be used for anything else; Only known to Snyk and your webhook transport consuming code;
  --url: string # Webhooks can only be configured for URLs using the `https` protocol. `http` is not allowed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/org/{org_id}/webhooks"))
  let req_body = {"secret": $secret, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a webhook
#
# DELETE /org/{orgId}/webhooks/{webhookId}
# operationId: Delete a webhook
export def "org-webhooks delete" [
  org_id: string
  webhook_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), webhook_id: (encode-path-segment $webhook_id)} | format pattern "/org/{org_id}/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a webhook
#
# GET /org/{orgId}/webhooks/{webhookId}
# operationId: Retrieve a webhook
export def "org-webhooks get" [
  org_id: string
  webhook_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), webhook_id: (encode-path-segment $webhook_id)} | format pattern "/org/{org_id}/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping a webhook
#
# POST /org/{orgId}/webhooks/{webhookId}/ping
# operationId: Ping a webhook
export def "org-webhooks-ping ping" [
  org_id: string
  webhook_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), webhook_id: (encode-path-segment $webhook_id)} | format pattern "/org/{org_id}/webhooks/{webhook_id}/ping"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the organizations a user belongs to
#
# GET /orgs
# operationId: List all the organizations a user belongs to
export def "orgs list-list-organizations-user-belongs" [
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
  let full_url = (build-url $base "/orgs")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get issue counts
#
# POST /reporting/counts/issues
# operationId: Get issue counts
# --filters shape: {fixable?: bool, ignored?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
export def "reporting-counts-issues get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The date you wish to fetch results from, in the format `YYYY-MM-DD` (e.g. 2017-07-01)
  --qp-to: string # The date you wish to fetch results until, in the format `YYYY-MM-DD` (e.g. 2017-07-03)
  --group-by: string@group-by-completer # The field to group results by (e.g. severity)
  --filters: record # shape: {fixable?: bool, ignored?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/counts/issues" $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get latest issue counts
#
# POST /reporting/counts/issues/latest
# operationId: Get latest issue counts
# --filters shape: {fixable?: bool, ignored?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
export def "reporting-counts-issues-latest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-by: string@group-by-completer # The field to group results by (e.g. severity)
  --filters: record # shape: {fixable?: bool, ignored?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/counts/issues/latest" $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get project counts
#
# POST /reporting/counts/projects
# operationId: Get project counts
# --filters shape: {languages?: list, orgs: any, projects?: any}
export def "reporting-counts-projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The date you wish to fetch results from, in the format `YYYY-MM-DD` (e.g. 2017-07-01)
  --qp-to: string # The date you wish to fetch results until, in the format `YYYY-MM-DD` (e.g. 2017-07-03)
  --filters: record # shape: {languages?: list, orgs: any, projects?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/counts/projects" $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get latest project counts
#
# POST /reporting/counts/projects/latest
# operationId: Get latest project counts
# --filters shape: {languages?: list, orgs: any, projects?: any}
export def "reporting-counts-projects-latest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # shape: {languages?: list, orgs: any, projects?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reporting/counts/projects/latest")
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get test counts
#
# POST /reporting/counts/tests
# operationId: Get test counts
# --filters shape: {isPrivate?: bool, issuesPrevented?: bool, orgs: any, projects?: any}
export def "reporting-counts-tests get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The date you wish to count tests from, in the format `YYYY-MM-DD` (e.g. 2017-07-01)
  --qp-to: string # The date you wish to count tests until, in the format `YYYY-MM-DD` (e.g. 2017-07-03)
  --group-by: string@group-by-completer-1 # The field to group results by (e.g. isPrivate)
  --filters: record # shape: {isPrivate?: bool, issuesPrevented?: bool, orgs: any, projects?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/counts/tests" $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get list of issues
#
# POST /reporting/issues/
# operationId: Get list of issues
# --filters shape: {exploitMaturity?: list, fixable?: bool, identifier?: string, ignored?: bool, isFixed?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, issues?: any, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
export def "reporting-issues get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The date you wish to fetch results from, in the format `YYYY-MM-DD` (e.g. 2017-07-01)
  --qp-to: string # The date you wish to fetch results until, in the format `YYYY-MM-DD` (e.g. 2017-07-07)
  --page: float # The page of results to request (e.g. 1)
  --per-page: float # The number of results to return per page (Maximum: 1000) (e.g. 100)
  --sort-by: string@sort-by-completer-2 # The key to sort results by (e.g. issueTitle)
  --order: string # The direction to sort results. (e.g. asc)
  --group-by: string@group-by-completer-2 # Set to issue to group the same issue in multiple projects (e.g. issue)
  --filters: record # shape: {exploitMaturity?: list, fixable?: bool, identifier?: string, ignored?: bool, isFixed?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, issues?: any, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/issues/" $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get list of latest issues
#
# POST /reporting/issues/latest
# operationId: Get list of latest issues
# --filters shape: {exploitMaturity?: list, fixable?: bool, identifier?: string, ignored?: bool, isFixed?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, issues?: any, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
export def "reporting-issues-latest get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page of results to request (e.g. 1)
  --per-page: float # The number of results to return per page (Maximum: 1000) (e.g. 100)
  --sort-by: string@sort-by-completer-2 # The key to sort results by (e.g. issueTitle)
  --order: string # The direction to sort results. (e.g. asc)
  --group-by: string@group-by-completer-2 # Set to issue to group the same issue in multiple projects (e.g. issue)
  --filters: record # shape: {exploitMaturity?: list, fixable?: bool, identifier?: string, ignored?: bool, isFixed?: bool, isPatchable?: bool, isPinnable?: bool, isUpgradable?: bool, issues?: any, languages?: list, orgs: any, patched?: bool, priorityScore?: record, projects?: any, severity?: list, types?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $per_page "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reporting/issues/latest" $qp)
  let req_body = {"filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test composer.json & composer.lock file
#
# POST /test/composer
# operationId: Test composer.json & composer.lock file
# --files shape: {additional: list, target: record}
export def "test-composer lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional: list, target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/composer")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test Dep Graph
#
# POST /test/dep-graph
# operationId: Test Dep Graph
# --depGraph shape: {graph: record, pkgManager: record, pkgs: list, schemaVersion: string}
export def "test-dep-graph test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  dep_graph: record # A [DepGraph data object](https://github.com/snyk/dep-graph#depgraphdata) defining all packages and their relationships. — shape: {graph: record, pkgManager: record, pkgs: list, schemaVersion: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/test/dep-graph" $qp)
  let req_body = {"depGraph": $dep_graph} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test Gopkg.toml & Gopkg.lock File
#
# POST /test/golangdep
# operationId: Test Gopkg.toml & Gopkg.lock File
# --files shape: {additional: list, target: record}
export def "test-golangdep lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional: list, target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/test/golangdep" $qp)
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test vendor.json File
#
# POST /test/govendor
# operationId: Test vendor.json File
# --files shape: {target: record}
export def "test-govendor create-json-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/govendor")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test gradle file
#
# POST /test/gradle
# operationId: Test gradle file
# --files shape: {target: record}
export def "test-gradle test-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/gradle")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test for issues in a public package by group, name and version
#
# GET /test/gradle/{group}/{name}/{version}
# operationId: Test for issues in a public package by group, name and version
export def "test-gradle test-for-issues-in-public-package-by-group-and" [
  group: string
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group: (encode-path-segment $group), name: (encode-path-segment $name), version: (encode-path-segment $version)} | format pattern "/test/gradle/{group}/{name}/{version}") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test maven file
#
# POST /test/maven
# operationId: Test maven file
# --files shape: {additional?: list, target: record}
export def "test-maven test-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The Maven repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional?: list, target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/test/maven" $qp)
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test for issues in a public package by group id, artifact id and version
#
# GET /test/maven/{groupId}/{artifactId}/{version}
# operationId: Test for issues in a public package by group id, artifact id and version
export def "test-maven test-for-issues-in-public-package-by-group-id-artifact-and" [
  group_id: string
  artifact_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The Maven repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), artifact_id: (encode-path-segment $artifact_id), version: (encode-path-segment $version)} | format pattern "/test/maven/{group_id}/{artifact_id}/{version}") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test package.json & package-lock.json File
#
# POST /test/npm
# operationId: Test package.json & package-lock.json File
# --files shape: {additional?: list, target: record}
export def "test-npm create-json-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {additional?: list, target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/npm")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test for issues in a public package by name and version
#
# GET /test/npm/{packageName}/{version}
# operationId: Test for issues in a public package by name and version
export def "test-npm test-for-issues-in-public-package-by-name-and" [
  package_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({package_name: (encode-path-segment $package_name), version: (encode-path-segment $version)} | format pattern "/test/npm/{package_name}/{version}") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test requirements.txt file
#
# POST /test/pip
# operationId: Test requirements.txt file
# --files shape: {target: record}
export def "test-pip create-txt-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/pip")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test for issues in a public package by name and version
#
# GET /test/pip/{packageName}/{version}
export def "test-pip get" [
  package_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({package_name: (encode-path-segment $package_name), version: (encode-path-segment $version)} | format pattern "/test/pip/{package_name}/{version}") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test gemfile.lock file
#
# POST /test/rubygems
# operationId: Test gemfile.lock file
# --files shape: {target: record}
export def "test-rubygems lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/rubygems")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test for issues in a public gem by name and version
#
# GET /test/rubygems/{gemName}/{version}
# operationId: Test for issues in a public gem by name and version
export def "test-rubygems test-for-issues-in-public-gem-by-name-and" [
  gem_name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({gem_name: (encode-path-segment $gem_name), version: (encode-path-segment $version)} | format pattern "/test/rubygems/{gem_name}/{version}") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test sbt file
#
# POST /test/sbt
# operationId: Test sbt file
# --files shape: {target: record}
export def "test-sbt test-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: base64)
  files: record # The manifest files: — shape: {target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/sbt")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Test for issues in a public package by group id, artifact id and version
#
# GET /test/sbt/{groupId}/{artifactId}/{version}
export def "test-sbt get" [
  group_id: string
  artifact_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org: string # The organization to test the package with. See "The Snyk organization for a request" above. (e.g. 9695cbb1-3a87-4d6f-8ae1-61a1c37ee9f7)
  --repository: string # The repository hosting this package. The default value is Maven Central. More than one value is supported, in order. (e.g. https://repo1.maven.org/maven2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org" $org "scalar") (serialize-qp "repository" $repository "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), artifact_id: (encode-path-segment $artifact_id), version: (encode-path-segment $version)} | format pattern "/test/sbt/{group_id}/{artifact_id}/{version}") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test package.json & yarn.lock File
#
# POST /test/yarn
# operationId: Test package.json & yarn.lock File
# --files shape: {additional?: list, target: record}
export def "test-yarn lock-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --encoding: string@encoding-completer # the encoding for the manifest files sent. (default: plain)
  files: record # The manifest files: — shape: {additional?: list, target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/test/yarn")
  let req_body = {"encoding": $encoding, "files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get My Details
#
# GET /user/me
# operationId: Get My Details
export def "user-me get-my-details" [
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
  let full_url = (build-url $base "/user/me")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organization notification settings
#
# GET /user/me/notification-settings/org/{orgId}
# operationId: Get organization notification settings
export def "user-me-notification-settings-org get-organization" [
  org_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/user/me/notification-settings/org/{org_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify organization notification settings
#
# PUT /user/me/notification-settings/org/{orgId}
# operationId: Modify organization notification settings
# --new-issues-remediations shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
# --project-imported shape: {enabled: bool}
# --test-limit shape: {enabled: bool}
# --weekly-report shape: {enabled: bool}
export def "user-me-notification-settings-org update-modify-organization" [
  org_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-issues-remediations: record # shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
  --project-imported: record # shape: {enabled: bool}
  --test-limit: record # shape: {enabled: bool}
  --weekly-report: record # shape: {enabled: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id)} | format pattern "/user/me/notification-settings/org/{org_id}"))
  let req_body = {"new-issues-remediations": $new_issues_remediations, "project-imported": $project_imported, "test-limit": $test_limit, "weekly-report": $weekly_report} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get project notification settings
#
# GET /user/me/notification-settings/org/{orgId}/project/{projectId}
# operationId: Get project notification settings
export def "user-me-notification-settings-org-project get" [
  org_id: string
  project_id: string
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
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/user/me/notification-settings/org/{org_id}/project/{project_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify project notification settings
#
# PUT /user/me/notification-settings/org/{orgId}/project/{projectId}
# operationId: Modify project notification settings
# --new-issues-remediations shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
export def "user-me-notification-settings-org-project update-modify" [
  org_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-issues-remediations: record # shape: {enabled: bool, issueSeverity: "all"|"high", issueType: "all"|"vuln"|"license"|"none"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({org_id: (encode-path-segment $org_id), project_id: (encode-path-segment $project_id)} | format pattern "/user/me/notification-settings/org/{org_id}/project/{project_id}"))
  let req_body = {"new-issues-remediations": $new_issues_remediations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get User Details
#
# GET /user/{userId}
# operationId: Get User Details
export def "user get-details" [
  user_id: string
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
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/user/{user_id}"))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
