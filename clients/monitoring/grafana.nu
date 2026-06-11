# Auto-generated client for Grafana HTTP API. v0.0.1
# Source: https://raw.githubusercontent.com/grafana/grafana/main/public/api-merged.json
# Auth: --token flag or $env.GRAFANA_HTTP_API_TOKEN

const BASE_URL = "http://localhost/api"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GRAFANA_HTTP_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["http://localhost/api" "https://localhost/api"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def type-completer [] { ["alert" "annotation"] }
def permission-completer [] { ["Edit" "View"] }
def kind-completer [] { ["1"] }
def sortDirection-completer [] { ["alpha-asc" "alpha-desc"] }
def role-completer [] { ["Admin" "Editor" "None" "Viewer"] }
def theme-completer [] { ["dark" "light" "system"] }
def theme-completer-1 [] { ["dark" "light"] }
def sort-completer [] { ["time-asc" "time-desc"] }
def type-completer-1 [] { ["dash-db" "dash-folder"] }
def sort-completer-1 [] { ["alpha-asc" "alpha-desc"] }
def execErrState-completer [] { ["Alerting" "Error" "OK"] }
def noDataState-completer [] { ["Alerting" "NoData" "OK"] }
def format-completer [] { ["hcl" "json" "yaml"] }
def accept-completer [] { ["application/json" "application/terraform+hcl" "application/yaml" "text/hcl" "text/yaml"] }
def type-completer-2 [] { ["alertmanager" "dingding" "discord" "email" "googlechat" "kafka" "line" "opsgenie" "pagerduty" "pushover" "sensugo" "slack" "teams" "telegram" "threema" "victorops" "webhook" "wecom"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "access-control-roles listRoles" } } | get name | first)
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

# Get all roles.
#
# GET /access-control/roles
# operationId: listRoles
export def "access-control-roles listRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delegatable: string@bool-completer
  --includeHidden: string@bool-completer
  --targetOrgId: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "delegatable" $delegatable "scalar") (serialize-qp "includeHidden" $includeHidden "scalar") (serialize-qp "targetOrgId" $targetOrgId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/access-control/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new custom role.
#
# POST /access-control/roles
# operationId: createRole
# --permissions item shape: {action?: string, created?: string, scope?: string, updated?: string}
export def "access-control-roles createRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --displayName: string
  --global: string@bool-completer
  --group: string
  --hidden: string@bool-completer
  --name: string
  --permissions: list # item shape: {action?: string, created?: string, scope?: string, updated?: string}
  --uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access-control/roles")
  let body = {description: $description, displayName: $displayName, global: $global, group: $group, hidden: $hidden, name: $name, permissions: $permissions, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a role.
#
# GET /access-control/roles/{roleUID}
# operationId: getRole
export def "access-control-roles get" [
  roleUID: string
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
  let full_url = (build-url $base $"/access-control/roles/($roleUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom role.
#
# PUT /access-control/roles/{roleUID}
# operationId: updateRole
# --permissions item shape: {action?: string, created?: string, scope?: string, updated?: string}
export def "access-control-roles updateRole" [
  roleUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string
  displayName: string
  --global: string@bool-completer
  group: string
  --hidden: string@bool-completer
  --name: string
  --permissions: list # item shape: {action?: string, created?: string, scope?: string, updated?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/roles/($roleUID)")
  let body = {description: $description, displayName: $displayName, global: $global, group: $group, hidden: $hidden, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom role.
#
# DELETE /access-control/roles/{roleUID}
# operationId: deleteRole
export def "access-control-roles delete" [
  roleUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: string@bool-completer
  --global: string@bool-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "global" $global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-control/roles/($roleUID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get role assignments.
#
# GET /access-control/roles/{roleUID}/assignments
# operationId: getRoleAssignments
export def "access-control-roles-assignments get" [
  roleUID: string
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
  let full_url = (build-url $base $"/access-control/roles/($roleUID)/assignments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set role assignments.
#
# PUT /access-control/roles/{roleUID}/assignments
# operationId: setRoleAssignments
export def "access-control-roles-assignments setRoleAssignments" [
  roleUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --service-accounts: list
  --teams: list
  --users: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/roles/($roleUID)/assignments")
  let body = {service_accounts: $service_accounts, teams: $teams, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get status.
#
# GET /access-control/status
# operationId: getAccessControlStatus
export def "access-control-status get" [
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
  let full_url = (build-url $base "/access-control/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List roles assigned to multiple teams.
#
# POST /access-control/teams/roles/search
# operationId: listTeamsRoles
export def "access-control-teams-roles-search listTeamsRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeHidden: string@bool-completer
  --orgId: int # format: int64
  --teamIds: list
  --userIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access-control/teams/roles/search")
  let body = {includeHidden: $includeHidden, orgId: $orgId, teamIds: $teamIds, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get team roles.
#
# GET /access-control/teams/{teamId}/roles
# operationId: listTeamRoles
export def "access-control-teams-roles listTeamRoles" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetOrgId: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetOrgId" $targetOrgId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-control/teams/($teamId)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update team role.
#
# PUT /access-control/teams/{teamId}/roles
# operationId: setTeamRoles
export def "access-control-teams-roles setTeamRoles" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetOrgId: int # format: int64
  --includeHidden: string@bool-completer
  --roleUids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetOrgId" $targetOrgId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-control/teams/($teamId)/roles" $qp)
  let body = {includeHidden: $includeHidden, roleUids: $roleUids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add team role.
#
# POST /access-control/teams/{teamId}/roles
# operationId: addTeamRole
export def "access-control-teams-roles addTeamRole" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --roleUid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/teams/($teamId)/roles")
  let body = {roleUid: $roleUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove team role.
#
# DELETE /access-control/teams/{teamId}/roles/{roleUID}
# operationId: removeTeamRole
export def "access-control-teams-roles removeTeamRole" [
  roleUID: string
  teamId: int
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
  let full_url = (build-url $base $"/access-control/teams/($teamId)/roles/($roleUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List roles assigned to multiple users.
#
# POST /access-control/users/roles/search
# operationId: listUsersRoles
export def "access-control-users-roles-search listUsersRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeHidden: string@bool-completer
  --orgId: int # format: int64
  --teamIds: list
  --userIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/access-control/users/roles/search")
  let body = {includeHidden: $includeHidden, orgId: $orgId, teamIds: $teamIds, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List roles assigned to a user.
#
# GET /access-control/users/{userId}/roles
# operationId: listUserRoles
export def "access-control-users-roles listUserRoles" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeHidden: string@bool-completer
  --targetOrgId: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeHidden" $includeHidden "scalar") (serialize-qp "targetOrgId" $targetOrgId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-control/users/($userId)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user role assignments.
#
# PUT /access-control/users/{userId}/roles
# operationId: setUserRoles
export def "access-control-users-roles setUserRoles" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetOrgId: int # format: int64
  --global: string@bool-completer
  --includeHidden: string@bool-completer
  --roleUids: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetOrgId" $targetOrgId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-control/users/($userId)/roles" $qp)
  let body = {global: $global, includeHidden: $includeHidden, roleUids: $roleUids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a user role assignment.
#
# POST /access-control/users/{userId}/roles
# operationId: addUserRole
export def "access-control-users-roles addUserRole" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --global: string@bool-completer
  --roleUid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/users/($userId)/roles")
  let body = {global: $global, roleUid: $roleUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a user role assignment.
#
# DELETE /access-control/users/{userId}/roles/{roleUID}
# operationId: removeUserRole
export def "access-control-users-roles removeUserRole" [
  roleUID: string
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --global: string@bool-completer # A flag indicating if the assignment is global or not. If set to false, the default org ID of the authenticated user will be used from the request to remove assignment.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "global" $global "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/access-control/users/($userId)/roles/($roleUID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a description of a resource's access control properties.
#
# GET /access-control/{resource}/description
# operationId: getResourceDescription
export def "access-control-description get" [
  resource: string
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
  let full_url = (build-url $base $"/access-control/($resource)/description")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get permissions for a resource.
#
# GET /access-control/{resource}/{resourceID}
# operationId: getResourcePermissions
export def "access-control get" [
  resource: string
  resourceID: string
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
  let full_url = (build-url $base $"/access-control/($resource)/($resourceID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set resource permissions.
#
# POST /access-control/{resource}/{resourceID}
# operationId: setResourcePermissions
# --permissions item shape: {builtInRole?: string, permission?: string, teamId?: int, userId?: int}
export def "access-control setResourcePermissions" [
  resource: string
  resourceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissions: list # item shape: {builtInRole?: string, permission?: string, teamId?: int, userId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/($resource)/($resourceID)")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set resource permissions for a built-in role.
#
# POST /access-control/{resource}/{resourceID}/builtInRoles/{builtInRole}
# operationId: setResourcePermissionsForBuiltInRole
export def "access-control-built-in-roles setResourcePermissionsForBuiltInRole" [
  resource: string
  resourceID: string
  builtInRole: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/($resource)/($resourceID)/builtInRoles/($builtInRole)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set resource permissions for a team.
#
# POST /access-control/{resource}/{resourceID}/teams/{teamID}
# operationId: setResourcePermissionsForTeam
export def "access-control-teams setResourcePermissionsForTeam" [
  resource: string
  resourceID: string
  teamID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/($resource)/($resourceID)/teams/($teamID)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set resource permissions for a user.
#
# POST /access-control/{resource}/{resourceID}/users/{userID}
# operationId: setResourcePermissionsForUser
export def "access-control-users setResourcePermissionsForUser" [
  resource: string
  resourceID: string
  userID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/access-control/($resource)/($resourceID)/users/($userID)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the current state of the LDAP background sync integration.
#
# GET /admin/ldap-sync-status
# operationId: getSyncStatus
export def "admin-ldap-sync-status get" [
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
  let full_url = (build-url $base "/admin/ldap-sync-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reloads the LDAP configuration.
#
# POST /admin/ldap/reload
# operationId: reloadLDAPCfg
export def "admin-ldap-reload reloadLDAPCfg" [
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
  let full_url = (build-url $base "/admin/ldap/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attempts to connect to all the configured LDAP servers and returns information on whenever they're available or not.
#
# GET /admin/ldap/status
# operationId: getLDAPStatus
export def "admin-ldap-status get" [
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
  let full_url = (build-url $base "/admin/ldap/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables a single Grafana user to be synchronized against LDAP.
#
# POST /admin/ldap/sync/{user_id}
# operationId: postSyncUserWithLDAP
export def "admin-ldap-sync post" [
  user_id: int
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
  let full_url = (build-url $base $"/admin/ldap/sync/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finds an user based on a username in LDAP. This helps illustrate how would the particular user be mapped in Grafana when synced.
#
# GET /admin/ldap/{user_name}
# operationId: getUserFromLDAP
export def "admin-ldap get" [
  user_name: string
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
  let full_url = (build-url $base $"/admin/ldap/($user_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# You need to have a permission with action `provisioning:reload` with scope `provisioners:accesscontrol`.
#
# POST /admin/provisioning/access-control/reload
# operationId: adminProvisioningReloadAccessControl
export def "admin-provisioning-access-control-reload adminProvisioningReloadAccessControl" [
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
  let full_url = (build-url $base "/admin/provisioning/access-control/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reload dashboard provisioning configurations.
#
# POST /admin/provisioning/dashboards/reload
# operationId: adminProvisioningReloadDashboards
export def "admin-provisioning-dashboards-reload adminProvisioningReloadDashboards" [
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
  let full_url = (build-url $base "/admin/provisioning/dashboards/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reload datasource provisioning configurations.
#
# POST /admin/provisioning/datasources/reload
# operationId: adminProvisioningReloadDatasources
export def "admin-provisioning-datasources-reload adminProvisioningReloadDatasources" [
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
  let full_url = (build-url $base "/admin/provisioning/datasources/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reload plugin provisioning configurations.
#
# POST /admin/provisioning/plugins/reload
# operationId: adminProvisioningReloadPlugins
export def "admin-provisioning-plugins-reload adminProvisioningReloadPlugins" [
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
  let full_url = (build-url $base "/admin/provisioning/plugins/reload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch settings.
#
# GET /admin/settings
# operationId: adminGetSettings
export def "admin-settings adminGetSettings" [
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
  let full_url = (build-url $base "/admin/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Grafana Stats.
#
# GET /admin/stats
# operationId: adminGetStats
export def "admin-stats adminGetStats" [
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
  let full_url = (build-url $base "/admin/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new user.
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
  --email: string
  --login: string
  --name: string
  --orgId: int # format: int64
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/users")
  let body = {email: $email, login: $login, name: $name, orgId: $orgId, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete global User.
#
# DELETE /admin/users/{user_id}
# operationId: adminDeleteUser
export def "admin-users adminDeleteUser" [
  user_id: int
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
  let full_url = (build-url $base $"/admin/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of all auth tokens (devices) that the user currently have logged in from.
#
# GET /admin/users/{user_id}/auth-tokens
# operationId: adminGetUserAuthTokens
export def "admin-users-auth-tokens adminGetUserAuthTokens" [
  user_id: int
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
  let full_url = (build-url $base $"/admin/users/($user_id)/auth-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable user.
#
# POST /admin/users/{user_id}/disable
# operationId: adminDisableUser
export def "admin-users-disable adminDisableUser" [
  user_id: int
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
  let full_url = (build-url $base $"/admin/users/($user_id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable user.
#
# POST /admin/users/{user_id}/enable
# operationId: adminEnableUser
export def "admin-users-enable adminEnableUser" [
  user_id: int
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
  let full_url = (build-url $base $"/admin/users/($user_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Logout user revokes all auth tokens (devices) for the user. User of issued auth tokens (devices) will no longer be logged in and will be required to authenticate again upon next activity.
#
# POST /admin/users/{user_id}/logout
# operationId: adminLogoutUser
export def "admin-users-logout adminLogoutUser" [
  user_id: int
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
  let full_url = (build-url $base $"/admin/users/($user_id)/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set password for user.
#
# PUT /admin/users/{user_id}/password
# operationId: adminUpdateUserPassword
export def "admin-users-password adminUpdateUserPassword" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($user_id)/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set permissions for user.
#
# PUT /admin/users/{user_id}/permissions
# operationId: adminUpdateUserPermissions
export def "admin-users-permissions adminUpdateUserPermissions" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isGrafanaAdmin: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($user_id)/permissions")
  let body = {isGrafanaAdmin: $isGrafanaAdmin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch user quota.
#
# GET /admin/users/{user_id}/quotas
# operationId: getUserQuota
export def "admin-users-quotas get" [
  user_id: int
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
  let full_url = (build-url $base $"/admin/users/($user_id)/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user quota.
#
# PUT /admin/users/{user_id}/quotas/{quota_target}
# operationId: updateUserQuota
export def "admin-users-quotas updateUserQuota" [
  quota_target: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int64
  --target: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($user_id)/quotas/($quota_target)")
  let body = {limit: $limit, target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke auth token for user.
#
# POST /admin/users/{user_id}/revoke-auth-token
# operationId: adminRevokeUserAuthToken
export def "admin-users-revoke-auth-token adminRevokeUserAuthToken" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authTokenId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/users/($user_id)/revoke-auth-token")
  let body = {authTokenId: $authTokenId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Annotations.
#
# GET /annotations
# operationId: getAnnotations
export def "annotations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: int # Find annotations created after specific epoch datetime in milliseconds. (format: int64)
  --qp-to: int # Find annotations created before specific epoch datetime in milliseconds. (format: int64)
  --userId: int # Limit response to annotations created by specific user. (format: int64)
  --alertId: int # Find annotations for a specified alert rule by its ID. deprecated: AlertID is deprecated and will be removed in future versions. Please use AlertUID instead. (format: int64)
  --alertUID: string # Find annotations for a specified alert rule by its UID.
  --dashboardId: int # Find annotations that are scoped to a specific dashboard (format: int64)
  --dashboardUID: string # Find annotations that are scoped to a specific dashboard
  --panelId: int # Find annotations that are scoped to a specific panel (format: int64)
  --limit: int # Max limit for results returned. (format: int64)
  --tags: list # Use this to filter organization annotations. Organization annotations are annotations from an annotation data source that are not connected specifically to a dashboard or panel. You can filter by multiple tags.
  --type: string@type-completer # Return alerts or user created annotations
  --matchAny: string@bool-completer # Match any or all tags
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "alertId" $alertId "scalar") (serialize-qp "alertUID" $alertUID "scalar") (serialize-qp "dashboardId" $dashboardId "scalar") (serialize-qp "dashboardUID" $dashboardUID "scalar") (serialize-qp "panelId" $panelId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "type" $type "scalar") (serialize-qp "matchAny" $matchAny "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/annotations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Annotation.
#
# POST /annotations
# operationId: postAnnotation
export def "annotations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboardId: int # format: int64
  --dashboardUID: string
  --data: record
  --panelId: int # format: int64
  --tags: list
  text: string
  --time: int # format: int64
  --timeEnd: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/annotations")
  let body = {dashboardId: $dashboardId, dashboardUID: $dashboardUID, data: $data, panelId: $panelId, tags: $tags, text: $text, time: $time, timeEnd: $timeEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Annotation in Graphite format.
#
# POST /annotations/graphite
# operationId: postGraphiteAnnotation
export def "annotations-graphite post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: string
  --tags: any
  --what: string
  --when: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/annotations/graphite")
  let body = {data: $data, tags: $tags, what: $what, when: $when} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete multiple annotations.
#
# POST /annotations/mass-delete
# operationId: massDeleteAnnotations
export def "annotations-mass-delete massDeleteAnnotations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --annotationId: int # format: int64
  --dashboardId: int # format: int64
  --dashboardUID: string
  --panelId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/annotations/mass-delete")
  let body = {annotationId: $annotationId, dashboardId: $dashboardId, dashboardUID: $dashboardUID, panelId: $panelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Annotations Tags.
#
# GET /annotations/tags
# operationId: getAnnotationTags
export def "annotations-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tag: string # Tag is a string that you can use to filter tags.
  --limit: string # Max limit for results returned. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/annotations/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Annotation by ID.
#
# GET /annotations/{annotation_id}
# operationId: getAnnotationByID
export def "annotations get" [
  annotation_id: string
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
  let full_url = (build-url $base $"/annotations/($annotation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Annotation.
#
# PUT /annotations/{annotation_id}
# operationId: updateAnnotation
export def "annotations updateAnnotation" [
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record
  --id: int # format: int64
  --tags: list
  --text: string
  --time: int # format: int64
  --timeEnd: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/annotations/($annotation_id)")
  let body = {data: $data, id: $id, tags: $tags, text: $text, time: $time, timeEnd: $timeEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Annotation By ID.
#
# DELETE /annotations/{annotation_id}
# operationId: deleteAnnotationByID
export def "annotations delete" [
  annotation_id: string
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
  let full_url = (build-url $base $"/annotations/($annotation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch Annotation.
#
# PATCH /annotations/{annotation_id}
# operationId: patchAnnotation
export def "annotations patch" [
  annotation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record
  --id: int # format: int64
  --tags: list
  --text: string
  --time: int # format: int64
  --timeEnd: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/annotations/($annotation_id)")
  let body = {data: $data, id: $id, tags: $tags, text: $text, time: $time, timeEnd: $timeEnd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all devices within the last 30 days
#
# GET /anonymous/devices
# operationId: listDevices
export def "anonymous-devices listDevices" [
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
  let full_url = (build-url $base "/anonymous/devices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all devices within the last 30 days
#
# GET /anonymous/search
# operationId: SearchDevices
export def "anonymous-search SearchDevices" [
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
  let full_url = (build-url $base "/anonymous/search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all cloud migration sessions that have been created.
#
# GET /cloudmigration/migration
# operationId: getSessionList
export def "cloudmigration-migration list" [
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
  let full_url = (build-url $base "/cloudmigration/migration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a migration session.
#
# POST /cloudmigration/migration
# operationId: createSession
export def "cloudmigration-migration createSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloudmigration/migration")
  let body = {authToken: $authToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a cloud migration session by its uid.
#
# GET /cloudmigration/migration/{uid}
# operationId: getSession
export def "cloudmigration-migration get" [
  uid: string
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
  let full_url = (build-url $base $"/cloudmigration/migration/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a migration session by its uid.
#
# DELETE /cloudmigration/migration/{uid}
# operationId: deleteSession
export def "cloudmigration-migration delete" [
  uid: string
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
  let full_url = (build-url $base $"/cloudmigration/migration/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger the creation of an instance snapshot associated with the provided session.
#
# POST /cloudmigration/migration/{uid}/snapshot
# operationId: createSnapshot
export def "cloudmigration-migration-snapshot createSnapshot" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceTypes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cloudmigration/migration/($uid)/snapshot")
  let body = {resourceTypes: $resourceTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metadata about a snapshot, including where it is in its processing and final results.
#
# GET /cloudmigration/migration/{uid}/snapshot/{snapshotUid}
# operationId: getSnapshot
export def "cloudmigration-migration-snapshot get" [
  uid: string
  snapshotUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resultPage: int # ResultPage is used for pagination with ResultLimit (format: int64, default: 1)
  --resultLimit: int # Max limit for snapshot results returned. (format: int64, default: 100)
  --resultSortColumn: string # ResultSortColumn can be used to override the default system sort. Valid values are "name", "resource_type", and "status". (default: default)
  --resultSortOrder: string # ResultSortOrder is used with ResultSortColumn. Valid values are ASC and DESC. (default: ASC)
  --errorsOnly: string@bool-completer # ErrorsOnly is used to only return resources with error statuses (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resultPage" $resultPage "scalar") (serialize-qp "resultLimit" $resultLimit "scalar") (serialize-qp "resultSortColumn" $resultSortColumn "scalar") (serialize-qp "resultSortOrder" $resultSortOrder "scalar") (serialize-qp "errorsOnly" $errorsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cloudmigration/migration/($uid)/snapshot/($snapshotUid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a snapshot, wherever it is in its processing chain.
#
# POST /cloudmigration/migration/{uid}/snapshot/{snapshotUid}/cancel
# operationId: cancelSnapshot
export def "cloudmigration-migration-snapshot-cancel cancelSnapshot" [
  uid: string
  snapshotUid: string
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
  let full_url = (build-url $base $"/cloudmigration/migration/($uid)/snapshot/($snapshotUid)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a snapshot to the Grafana Migration Service for processing.
#
# POST /cloudmigration/migration/{uid}/snapshot/{snapshotUid}/upload
# operationId: uploadSnapshot
export def "cloudmigration-migration-snapshot-upload uploadSnapshot" [
  uid: string
  snapshotUid: string
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
  let full_url = (build-url $base $"/cloudmigration/migration/($uid)/snapshot/($snapshotUid)/upload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of snapshots for a session.
#
# GET /cloudmigration/migration/{uid}/snapshots
# operationId: getShapshotList
export def "cloudmigration-migration-snapshots get" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page is used for pagination with limit (format: int64, default: 1)
  --limit: int # Max limit for results returned. (format: int64, default: 100)
  --qp-sort: string # Sort with value latest to return results sorted in descending order.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/cloudmigration/migration/($uid)/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the resource dependencies graph for the current set of migratable resources.
#
# GET /cloudmigration/resources/dependencies
# operationId: getResourceDependencies
export def "cloudmigration-resources-dependencies get" [
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
  let full_url = (build-url $base "/cloudmigration/resources/dependencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the cloud migration token if it exists.
#
# GET /cloudmigration/token
# operationId: getCloudMigrationToken
export def "cloudmigration-token get" [
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
  let full_url = (build-url $base "/cloudmigration/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create gcom access token.
#
# POST /cloudmigration/token
# operationId: createCloudMigrationToken
export def "cloudmigration-token createCloudMigrationToken" [
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
  let full_url = (build-url $base "/cloudmigration/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a cloud migration token.
#
# DELETE /cloudmigration/token/{uid}
# operationId: deleteCloudMigrationToken
export def "cloudmigration-token delete" [
  uid: string
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
  let full_url = (build-url $base $"/cloudmigration/token/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Grafana-managed alert rules that were imported from Prometheus-compatible sources, grouped by namespace.
#
# GET /convert/api/prom/rules
# operationId: RouteConvertPrometheusCortexGetRules
export def "convert-prom-rules RouteConvertPrometheusCortexGetRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Body: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/api/prom/rules")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Converts the submitted rule groups into Grafana-Managed Rules.
#
# POST /convert/api/prom/rules
# operationId: RouteConvertPrometheusCortexPostRuleGroups
export def "convert-prom-rules RouteConvertPrometheusCortexPostRuleGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, errorType: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/api/prom/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets Grafana-managed alert rules that were imported from Prometheus-compatible sources for a specified namespace (folder).
#
# GET /convert/api/prom/rules/{NamespaceTitle}
# operationId: RouteConvertPrometheusCortexGetNamespace
export def "convert-prom-rules RouteConvertPrometheusCortexGetNamespace" [
  NamespaceTitle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Body: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/api/prom/rules/($NamespaceTitle)")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Converts a Prometheus rule group into a Grafana rule group and creates or updates it within the specified namespace.
#
# POST /convert/api/prom/rules/{NamespaceTitle}
# operationId: RouteConvertPrometheusCortexPostRuleGroup
# --rules item shape: {alert?: string, annotations?: record, expr?: string, for?: string, keep_firing_for?: string, labels?: record, record?: string}
export def "convert-prom-rules RouteConvertPrometheusCortexPostRuleGroup" [
  NamespaceTitle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-grafana-alerting-datasource-uid: string
  --x-grafana-alerting-recording-rules-paused: string@bool-completer
  --x-grafana-alerting-alert-rules-paused: string@bool-completer
  --x-grafana-alerting-target-datasource-uid: string
  --x-grafana-alerting-folder-uid: string
  --x-grafana-alerting-notification-settings: string
  --interval: int # A Duration represents the elapsed time between two instants as an int64 nanosecond count. The representation limits the largest representable duration to approximately 290 years. (format: int64)
  --labels: record
  --limit: int # format: int64
  --name: string
  --query-offset: string
  --rules: list # item shape: {alert?: string, annotations?: record, expr?: string, for?: string, keep_firing_for?: string, labels?: record, record?: string}
]: any -> record<error: string, errorType: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/api/prom/rules/($NamespaceTitle)")
  let body = {interval: $interval, labels: $labels, limit: $limit, name: $name, query_offset: $query_offset, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-grafana-alerting-datasource-uid": $x_grafana_alerting_datasource_uid, "x-grafana-alerting-recording-rules-paused": $x_grafana_alerting_recording_rules_paused, "x-grafana-alerting-alert-rules-paused": $x_grafana_alerting_alert_rules_paused, "x-grafana-alerting-target-datasource-uid": $x_grafana_alerting_target_datasource_uid, "x-grafana-alerting-folder-uid": $x_grafana_alerting_folder_uid, "x-grafana-alerting-notification-settings": $x_grafana_alerting_notification_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes all rule groups that were imported from Prometheus-compatible sources within the specified namespace.
#
# DELETE /convert/api/prom/rules/{NamespaceTitle}
# operationId: RouteConvertPrometheusCortexDeleteNamespace
export def "convert-prom-rules RouteConvertPrometheusCortexDeleteNamespace" [
  NamespaceTitle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, errorType: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/api/prom/rules/($NamespaceTitle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a single rule group in Prometheus-compatible format if it was imported from a Prometheus-compatible source.
#
# GET /convert/api/prom/rules/{NamespaceTitle}/{Group}
# operationId: RouteConvertPrometheusCortexGetRuleGroup
export def "convert-prom-rules RouteConvertPrometheusCortexGetRuleGroup" [
  NamespaceTitle: string
  Group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<interval: int, labels: record, limit: int, name: string, query_offset: string, rules: table<alert: string, annotations: record, expr: string, for: string, keep_firing_for: string, labels: record, record: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/api/prom/rules/($NamespaceTitle)/($Group)")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a specific rule group if it was imported from a Prometheus-compatible source.
#
# DELETE /convert/api/prom/rules/{NamespaceTitle}/{Group}
# operationId: RouteConvertPrometheusCortexDeleteRuleGroup
export def "convert-prom-rules RouteConvertPrometheusCortexDeleteRuleGroup" [
  NamespaceTitle: string
  Group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, errorType: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/api/prom/rules/($NamespaceTitle)/($Group)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Grafana-managed alert rules that were imported from Prometheus-compatible sources, grouped by namespace.
#
# GET /convert/prometheus/config/v1/rules
# operationId: RouteConvertPrometheusGetRules
export def "convert-prometheus-config-rules RouteConvertPrometheusGetRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Body: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/prometheus/config/v1/rules")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Converts the submitted rule groups into Grafana-Managed Rules.
#
# POST /convert/prometheus/config/v1/rules
# operationId: RouteConvertPrometheusPostRuleGroups
export def "convert-prometheus-config-rules RouteConvertPrometheusPostRuleGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, errorType: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/convert/prometheus/config/v1/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets Grafana-managed alert rules that were imported from Prometheus-compatible sources for a specified namespace (folder).
#
# GET /convert/prometheus/config/v1/rules/{NamespaceTitle}
# operationId: RouteConvertPrometheusGetNamespace
export def "convert-prometheus-config-rules RouteConvertPrometheusGetNamespace" [
  NamespaceTitle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Body: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/prometheus/config/v1/rules/($NamespaceTitle)")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Converts a Prometheus rule group into a Grafana rule group and creates or updates it within the specified namespace.
#
# POST /convert/prometheus/config/v1/rules/{NamespaceTitle}
# operationId: RouteConvertPrometheusPostRuleGroup
# --rules item shape: {alert?: string, annotations?: record, expr?: string, for?: string, keep_firing_for?: string, labels?: record, record?: string}
export def "convert-prometheus-config-rules RouteConvertPrometheusPostRuleGroup" [
  NamespaceTitle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-grafana-alerting-datasource-uid: string
  --x-grafana-alerting-recording-rules-paused: string@bool-completer
  --x-grafana-alerting-alert-rules-paused: string@bool-completer
  --x-grafana-alerting-target-datasource-uid: string
  --x-grafana-alerting-folder-uid: string
  --x-grafana-alerting-notification-settings: string
  --interval: int # A Duration represents the elapsed time between two instants as an int64 nanosecond count. The representation limits the largest representable duration to approximately 290 years. (format: int64)
  --labels: record
  --limit: int # format: int64
  --name: string
  --query-offset: string
  --rules: list # item shape: {alert?: string, annotations?: record, expr?: string, for?: string, keep_firing_for?: string, labels?: record, record?: string}
]: any -> record<error: string, errorType: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/prometheus/config/v1/rules/($NamespaceTitle)")
  let body = {interval: $interval, labels: $labels, limit: $limit, name: $name, query_offset: $query_offset, rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-grafana-alerting-datasource-uid": $x_grafana_alerting_datasource_uid, "x-grafana-alerting-recording-rules-paused": $x_grafana_alerting_recording_rules_paused, "x-grafana-alerting-alert-rules-paused": $x_grafana_alerting_alert_rules_paused, "x-grafana-alerting-target-datasource-uid": $x_grafana_alerting_target_datasource_uid, "x-grafana-alerting-folder-uid": $x_grafana_alerting_folder_uid, "x-grafana-alerting-notification-settings": $x_grafana_alerting_notification_settings} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes all rule groups that were imported from Prometheus-compatible sources within the specified namespace.
#
# DELETE /convert/prometheus/config/v1/rules/{NamespaceTitle}
# operationId: RouteConvertPrometheusDeleteNamespace
export def "convert-prometheus-config-rules RouteConvertPrometheusDeleteNamespace" [
  NamespaceTitle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, errorType: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/prometheus/config/v1/rules/($NamespaceTitle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a single rule group in Prometheus-compatible format if it was imported from a Prometheus-compatible source.
#
# GET /convert/prometheus/config/v1/rules/{NamespaceTitle}/{Group}
# operationId: RouteConvertPrometheusGetRuleGroup
export def "convert-prometheus-config-rules RouteConvertPrometheusGetRuleGroup" [
  NamespaceTitle: string
  Group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<interval: int, labels: record, limit: int, name: string, query_offset: string, rules: table<alert: string, annotations: record, expr: string, for: string, keep_firing_for: string, labels: record, record: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/prometheus/config/v1/rules/($NamespaceTitle)/($Group)")
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a specific rule group if it was imported from a Prometheus-compatible source.
#
# DELETE /convert/prometheus/config/v1/rules/{NamespaceTitle}/{Group}
# operationId: RouteConvertPrometheusDeleteRuleGroup
export def "convert-prometheus-config-rules RouteConvertPrometheusDeleteRuleGroup" [
  NamespaceTitle: string
  Group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: string, errorType: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/convert/prometheus/config/v1/rules/($NamespaceTitle)/($Group)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List snapshots.
#
# GET /dashboard/snapshots
# operationId: searchDashboardSnapshots
export def "dashboard-snapshots searchDashboardSnapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search Query
  --limit: int # Limit the number of returned results (format: int64, default: 1000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboard/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create / Update dashboard
#
# POST /dashboards/db
# DEPRECATED
# operationId: postDashboard
@deprecated
export def "dashboards-db post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --UpdatedAt: string # format: date-time
  --dashboard: record
  --folderId: int # Deprecated: use FolderUID instead (format: int64)
  --folderUid: string
  --isFolder: string@bool-completer
  --message: string
  --overwrite: string@bool-completer
  --userId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards/db")
  let body = {UpdatedAt: $UpdatedAt, dashboard: $dashboard, folderId: $folderId, folderUid: $folderUid, isFolder: $isFolder, message: $message, overwrite: $overwrite, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# NOTE: the home dashboard is configured in preferences.  This API will be removed in G13
#
# GET /dashboards/home
# DEPRECATED
# operationId: getHomeDashboard
@deprecated
export def "dashboards-home get" [
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
  let full_url = (build-url $base "/dashboards/home")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import dashboard.
#
# POST /dashboards/import
# operationId: importDashboard
# --inputs item shape: {name?: string, pluginId?: string, type?: string, value?: string}
export def "dashboards-import importDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboard: record
  --folderId: int # Deprecated: use FolderUID instead (format: int64)
  --folderUid: string
  --inputs: list # item shape: {name?: string, pluginId?: string, type?: string, value?: string}
  --overwrite: string@bool-completer
  --path: string
  --pluginId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboards/import")
  let body = {dashboard: $dashboard, folderId: $folderId, folderUid: $folderUid, inputs: $inputs, overwrite: $overwrite, path: $path, pluginId: $pluginId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Interpolate dashboard. This is an experimental endpoint under dashboardLibrary or suggestedDashboards feature flags and is subject to change.
#
# POST /dashboards/interpolate
# operationId: interpolateDashboard
export def "dashboards-interpolate interpolateDashboard" [
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
  let full_url = (build-url $base "/dashboards/interpolate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of public dashboards
#
# GET /dashboards/public-dashboards
# operationId: listPublicDashboards
export def "dashboards-public-dashboards listPublicDashboards" [
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
  let full_url = (build-url $base "/dashboards/public-dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all dashboards tags of an organization.
#
# GET /dashboards/tags
# DEPRECATED
# operationId: getDashboardTags
@deprecated
export def "dashboards-tags get" [
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
  let full_url = (build-url $base "/dashboards/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public dashboard by dashboardUid
#
# GET /dashboards/uid/{dashboardUid}/public-dashboards
# operationId: getPublicDashboard
export def "dashboards-uid-public-dashboards get" [
  dashboardUid: string
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
  let full_url = (build-url $base $"/dashboards/uid/($dashboardUid)/public-dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create public dashboard for a dashboard
#
# POST /dashboards/uid/{dashboardUid}/public-dashboards
# operationId: createPublicDashboard
export def "dashboards-uid-public-dashboards createPublicDashboard" [
  dashboardUid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessToken: string
  --annotationsEnabled: string@bool-completer
  --isEnabled: string@bool-completer
  --share: string
  --timeSelectionEnabled: string@bool-completer
  --uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/uid/($dashboardUid)/public-dashboards")
  let body = {accessToken: $accessToken, annotationsEnabled: $annotationsEnabled, isEnabled: $isEnabled, share: $share, timeSelectionEnabled: $timeSelectionEnabled, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete public dashboard for a dashboard
#
# DELETE /dashboards/uid/{dashboardUid}/public-dashboards/{uid}
# operationId: deletePublicDashboard
export def "dashboards-uid-public-dashboards delete" [
  dashboardUid: string
  uid: string
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
  let full_url = (build-url $base $"/dashboards/uid/($dashboardUid)/public-dashboards/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update public dashboard for a dashboard
#
# PATCH /dashboards/uid/{dashboardUid}/public-dashboards/{uid}
# operationId: updatePublicDashboard
export def "dashboards-uid-public-dashboards updatePublicDashboard" [
  dashboardUid: string
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessToken: string
  --annotationsEnabled: string@bool-completer
  --isEnabled: string@bool-completer
  --share: string
  --timeSelectionEnabled: string@bool-completer
  --body-uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/uid/($dashboardUid)/public-dashboards/($uid)")
  let body = {accessToken: $accessToken, annotationsEnabled: $annotationsEnabled, isEnabled: $isEnabled, share: $share, timeSelectionEnabled: $timeSelectionEnabled, uid: $body_uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get dashboard by uid.
#
# GET /dashboards/uid/{uid}
# DEPRECATED
# operationId: getDashboardByUID
@deprecated
export def "dashboards-uid get" [
  uid: string
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
  let full_url = (build-url $base $"/dashboards/uid/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete dashboard by uid.
#
# DELETE /dashboards/uid/{uid}
# DEPRECATED
# operationId: deleteDashboardByUID
@deprecated
export def "dashboards-uid delete" [
  uid: string
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
  let full_url = (build-url $base $"/dashboards/uid/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all existing permissions for the given dashboard.
#
# GET /dashboards/uid/{uid}/permissions
# DEPRECATED
# operationId: getDashboardPermissionsListByUID
@deprecated
export def "dashboards-uid-permissions get" [
  uid: string
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
  let full_url = (build-url $base $"/dashboards/uid/($uid)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates permissions for a dashboard.
#
# POST /dashboards/uid/{uid}/permissions
# DEPRECATED
# operationId: updateDashboardPermissionsByUID
# --items item shape: {permission?: int, role?: "None"|"Viewer"|"Editor"|"Admin", teamId?: int, userId?: int}
@deprecated
export def "dashboards-uid-permissions updateDashboardPermissionsByUID" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --items: list # item shape: {permission?: int, role?: "None"|"Viewer"|"Editor"|"Admin", teamId?: int, userId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/uid/($uid)/permissions")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore a dashboard to a given dashboard version using UID.
#
# POST /dashboards/uid/{uid}/restore
# DEPRECATED
# operationId: restoreDashboardVersionByUID
@deprecated
export def "dashboards-uid-restore restoreDashboardVersionByUID" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dashboards/uid/($uid)/restore")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all existing versions for the dashboard using UID.
#
# GET /dashboards/uid/{uid}/versions
# DEPRECATED
# operationId: getDashboardVersionsByUID
@deprecated
export def "dashboards-uid-versions list" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of results to return (format: int64, default: 0)
  --start: int # Version to start from when returning queries (format: int64, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dashboards/uid/($uid)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific dashboard version using UID.
#
# GET /dashboards/uid/{uid}/versions/{DashboardVersionID}
# DEPRECATED
# operationId: getDashboardVersionByUID
@deprecated
export def "dashboards-uid-versions get" [
  DashboardVersionID: int
  uid: string
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
  let full_url = (build-url $base $"/dashboards/uid/($uid)/versions/($DashboardVersionID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all data sources.
#
# GET /datasources
# operationId: getDataSources
export def "datasources get" [
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
  let full_url = (build-url $base "/datasources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a data source.
#
# POST /datasources
# operationId: addDataSource
export def "datasources addDataSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access: string
  --basicAuth: string@bool-completer
  --basicAuthUser: string
  --database: string
  --isDefault: string@bool-completer
  --jsonData: record
  --name: string
  --secureJsonData: record
  --type: string
  --uid: string
  --body-url: string
  --user: string
  --withCredentials: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datasources")
  let body = {access: $access, basicAuth: $basicAuth, basicAuthUser: $basicAuthUser, database: $database, isDefault: $isDefault, jsonData: $jsonData, name: $name, secureJsonData: $secureJsonData, type: $type, uid: $uid, url: $body_url, user: $user, withCredentials: $withCredentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all correlations.
#
# GET /datasources/correlations
# operationId: getCorrelations
export def "datasources-correlations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the maximum number of correlations to return per page (format: int64, default: 100)
  --page: int # Page index for starting fetching correlations (format: int64, default: 1)
  --sourceUID: list # Source datasource UID filter to be applied to correlations
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sourceUID" $sourceUID "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/datasources/correlations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get data source Id by Name. This function will be removed in the future.
#
# GET /datasources/id/{name}
# DEPRECATED
# operationId: getDataSourceIdByName
@deprecated
export def "datasources-id get" [
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
  let full_url = (build-url $base $"/datasources/id/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single data source by Name.  This function will be removed in the future.
#
# GET /datasources/name/{name}
# DEPRECATED
# operationId: getDataSourceByName
@deprecated
export def "datasources-name get" [
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
  let full_url = (build-url $base $"/datasources/name/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an existing data source by name. This function will be removed in the future.
#
# DELETE /datasources/name/{name}
# DEPRECATED
# operationId: deleteDataSourceByName
@deprecated
export def "datasources-name delete" [
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
  let full_url = (build-url $base $"/datasources/name/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Data source proxy GET calls.
#
# GET /datasources/proxy/uid/{uid}/{datasource_proxy_route}
# operationId: datasourceProxyGETByUIDcalls
export def "datasources-proxy-uid datasourceProxyGETByUIDcalls" [
  datasource_proxy_route: string
  uid: string
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
  let full_url = (build-url $base $"/datasources/proxy/uid/($uid)/($datasource_proxy_route)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Data source proxy POST calls.
#
# POST /datasources/proxy/uid/{uid}/{datasource_proxy_route}
# operationId: datasourceProxyPOSTByUIDcalls
export def "datasources-proxy-uid datasourceProxyPOSTByUIDcalls" [
  datasource_proxy_route: string
  uid: string
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
  let full_url = (build-url $base $"/datasources/proxy/uid/($uid)/($datasource_proxy_route)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Data source proxy DELETE calls.
#
# DELETE /datasources/proxy/uid/{uid}/{datasource_proxy_route}
# operationId: datasourceProxyDELETEByUIDcalls
export def "datasources-proxy-uid datasourceProxyDELETEByUIDcalls" [
  uid: string
  datasource_proxy_route: string
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
  let full_url = (build-url $base $"/datasources/proxy/uid/($uid)/($datasource_proxy_route)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all correlations originating from the given data source.
#
# GET /datasources/uid/{sourceUID}/correlations
# operationId: getCorrelationsBySourceUID
export def "datasources-uid-correlations list" [
  sourceUID: string
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
  let full_url = (build-url $base $"/datasources/uid/($sourceUID)/correlations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add correlation.
#
# POST /datasources/uid/{sourceUID}/correlations
# operationId: createCorrelation
# --config shape: {field: string, target: record, transformations?: list, type?: string}
export def "datasources-uid-correlations createCorrelation" [
  sourceUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # shape: {field: string, target: record, transformations?: list, type?: string}
  --description: string # Optional description of the correlation (e.g. Logs to Traces)
  --label: string # Optional label identifying the correlation (e.g. My label)
  --provisioned: string@bool-completer # True if correlation was created with provisioning. This makes it read-only.
  --targetUID: string # Target data source UID to which the correlation is created. required if type = query (e.g. PE1C5CBDA0504A6A3)
  --type: string # the type of correlation, either query for containing query information, or external for containing an external URL +enum
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/uid/($sourceUID)/correlations")
  let body = {config: $config, description: $description, label: $label, provisioned: $provisioned, targetUID: $targetUID, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a correlation.
#
# GET /datasources/uid/{sourceUID}/correlations/{correlationUID}
# operationId: getCorrelation
export def "datasources-uid-correlations get" [
  sourceUID: string
  correlationUID: string
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
  let full_url = (build-url $base $"/datasources/uid/($sourceUID)/correlations/($correlationUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a correlation.
#
# PATCH /datasources/uid/{sourceUID}/correlations/{correlationUID}
# operationId: updateCorrelation
# --config shape: {field?: string, target?: record, transformations?: list}
export def "datasources-uid-correlations updateCorrelation" [
  sourceUID: string
  correlationUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # shape: {field?: string, target?: record, transformations?: list}
  --description: string # Optional description of the correlation (e.g. Logs to Traces)
  --label: string # Optional label identifying the correlation (e.g. My label)
  --type: string # the type of correlation, either query for containing query information, or external for containing an external URL +enum
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/uid/($sourceUID)/correlations/($correlationUID)")
  let body = {config: $config, description: $description, label: $label, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single data source by UID.
#
# GET /datasources/uid/{uid}
# operationId: getDataSourceByUID
export def "datasources-uid get" [
  uid: string
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
  let full_url = (build-url $base $"/datasources/uid/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing data source.
#
# PUT /datasources/uid/{uid}
# operationId: updateDataSourceByUID
export def "datasources-uid updateDataSourceByUID" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access: string
  --basicAuth: string@bool-completer
  --basicAuthUser: string
  --database: string
  --isDefault: string@bool-completer
  --jsonData: record
  --name: string
  --secureJsonData: record
  --type: string
  --body-uid: string
  --body-url: string
  --user: string
  --version: int # The previous version -- used for optimistic locking (format: int64)
  --withCredentials: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/uid/($uid)")
  let body = {access: $access, basicAuth: $basicAuth, basicAuthUser: $basicAuthUser, database: $database, isDefault: $isDefault, jsonData: $jsonData, name: $name, secureJsonData: $secureJsonData, type: $type, uid: $body_uid, url: $body_url, user: $user, version: $version, withCredentials: $withCredentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing data source by UID.
#
# DELETE /datasources/uid/{uid}
# operationId: deleteDataSourceByUID
export def "datasources-uid delete" [
  uid: string
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
  let full_url = (build-url $base $"/datasources/uid/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a correlation.
#
# DELETE /datasources/uid/{uid}/correlations/{correlationUID}
# operationId: deleteCorrelation
export def "datasources-uid-correlations delete" [
  uid: string
  correlationUID: string
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
  let full_url = (build-url $base $"/datasources/uid/($uid)/correlations/($correlationUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health check request to the plugin datasource identified by the UID.
#
# GET /datasources/uid/{uid}/health
# operationId: checkDatasourceHealthWithUID
export def "datasources-uid-health checkDatasourceHealthWithUID" [
  uid: string
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
  let full_url = (build-url $base $"/datasources/uid/($uid)/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves LBAC rules for a team.
#
# GET /datasources/uid/{uid}/lbac/teams
# operationId: getTeamLBACRulesApi
export def "datasources-uid-lbac-teams get" [
  uid: string
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
  let full_url = (build-url $base $"/datasources/uid/($uid)/lbac/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates LBAC rules for a team.
#
# PUT /datasources/uid/{uid}/lbac/teams
# operationId: updateTeamLBACRulesApi
# --rules item shape: {rules?: list, teamId?: string, teamUid?: string}
export def "datasources-uid-lbac-teams updateTeamLBACRulesApi" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rules: list # item shape: {rules?: list, teamId?: string, teamUid?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/uid/($uid)/lbac/teams")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch data source resources.
#
# GET /datasources/uid/{uid}/resources/{datasource_proxy_route}
# operationId: callDatasourceResourceWithUID
export def "datasources-uid-resources callDatasourceResourceWithUID" [
  datasource_proxy_route: string
  uid: string
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
  let full_url = (build-url $base $"/datasources/uid/($uid)/resources/($datasource_proxy_route)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get cache config for a single data source
#
# GET /datasources/{dataSourceUID}/cache
# operationId: getDataSourceCacheConfig
export def "datasources-cache get" [
  dataSourceUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataSourceType: string
]: nothing -> record<created: string, dataSourceID: int, dataSourceUID: string, defaultTTLMs: int, enabled: bool, message: string, ttlQueriesMs: int, ttlResourcesMs: int, updated: string, useDefaultTTL: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataSourceType" $dataSourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/datasources/($dataSourceUID)/cache" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# set cache config for a single data source
#
# POST /datasources/{dataSourceUID}/cache
# operationId: setDataSourceCacheConfig
export def "datasources-cache setDataSourceCacheConfig" [
  dataSourceUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataSourceType: string
  --dataSourceID: int # format: int64
  --body-dataSourceUID: string
  --enabled: string@bool-completer
  --ttlQueriesMs: int # TTL MS, or "time to live", is how long a cached item will stay in the cache before it is removed (in milliseconds) (format: int64)
  --ttlResourcesMs: int # format: int64
  --useDefaultTTL: string@bool-completer # If UseDefaultTTL is enabled, then the TTLQueriesMS and TTLResourcesMS in this object is always sent as the default TTL located in grafana.ini
]: any -> record<created: string, dataSourceID: int, dataSourceUID: string, defaultTTLMs: int, enabled: bool, message: string, ttlQueriesMs: int, ttlResourcesMs: int, updated: string, useDefaultTTL: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataSourceType" $dataSourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/datasources/($dataSourceUID)/cache" $qp)
  let body = {dataSourceID: $dataSourceID, dataSourceUID: $body_dataSourceUID, enabled: $enabled, ttlQueriesMs: $ttlQueriesMs, ttlResourcesMs: $ttlResourcesMs, useDefaultTTL: $useDefaultTTL} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# clean cache for a single data source
#
# POST /datasources/{dataSourceUID}/cache/clean
# operationId: cleanDataSourceCache
export def "datasources-cache-clean cleanDataSourceCache" [
  dataSourceUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created: string, dataSourceID: int, dataSourceUID: string, defaultTTLMs: int, enabled: bool, message: string, ttlQueriesMs: int, ttlResourcesMs: int, updated: string, useDefaultTTL: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datasources/($dataSourceUID)/cache/clean")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# disable cache for a single data source
#
# POST /datasources/{dataSourceUID}/cache/disable
# operationId: disableDataSourceCache
export def "datasources-cache-disable disableDataSourceCache" [
  dataSourceUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataSourceType: string
]: nothing -> record<created: string, dataSourceID: int, dataSourceUID: string, defaultTTLMs: int, enabled: bool, message: string, ttlQueriesMs: int, ttlResourcesMs: int, updated: string, useDefaultTTL: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataSourceType" $dataSourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/datasources/($dataSourceUID)/cache/disable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# enable cache for a single data source
#
# POST /datasources/{dataSourceUID}/cache/enable
# operationId: enableDataSourceCache
export def "datasources-cache-enable enableDataSourceCache" [
  dataSourceUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataSourceType: string
]: nothing -> record<created: string, dataSourceID: int, dataSourceUID: string, defaultTTLMs: int, enabled: bool, message: string, ttlQueriesMs: int, ttlResourcesMs: int, updated: string, useDefaultTTL: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataSourceType" $dataSourceType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/datasources/($dataSourceUID)/cache/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DataSource query metrics with expressions.
#
# POST /ds/query
# operationId: queryMetricsWithExpressions
export def "ds-query queryMetricsWithExpressions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --debug: string@bool-completer
  --body-from: string # From Start time in epoch timestamps in milliseconds or relative using Grafana time units. (e.g. now-1h)
  queries: list # queries.refId – Specifies an identifier of the query. Is optional and default to “A”. queries.datasourceId – Specifies the data source to be queried. Each query in the request must have an unique datasourceId. queries.maxDataPoints - Species maximum amount of data points that dashboard panel can render. Is optional and default to 100. queries.intervalMs - Specifies the time interval in milliseconds of time series. Is optional and defaults to 1000. (e.g. [{datasource: {uid: PD8C576611E62080A}, format: table, intervalMs: 86400000, maxDataPoints: 1092, rawSql: SELECT 1 as valueOne, 2 as valueTwo, refId: A}])
  --body-to: string # To End time in epoch timestamps in milliseconds or relative using Grafana time units. (e.g. now)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ds/query")
  let body = {debug: $debug, from: $body_from, queries: $queries, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all folders.
#
# GET /folders
# DEPRECATED
# operationId: getFolders
@deprecated
export def "folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the maximum number of folders to return (format: int64, default: 1000)
  --page: int # Page index for starting fetching folders (format: int64, default: 1)
  --parentUid: string # The parent folder UID
  --permission: string@permission-completer # Set to `Edit` to return folders that the user can edit (default: View)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "parentUid" $parentUid "scalar") (serialize-qp "permission" $permission "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create folder.
#
# POST /folders
# DEPRECATED
# operationId: createFolder
@deprecated
export def "folders createFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  --parentUid: string
  --title: string
  --uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/folders")
  let body = {description: $description, parentUid: $parentUid, title: $title, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get folder by uid.
#
# GET /folders/{folder_uid}
# DEPRECATED
# operationId: getFolderByUID
@deprecated
export def "folders get" [
  folder_uid: string
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
  let full_url = (build-url $base $"/folders/($folder_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update folder.
#
# PUT /folders/{folder_uid}
# DEPRECATED
# operationId: updateFolder
@deprecated
export def "folders updateFolder" [
  folder_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # NewDescription it's an optional parameter used for overriding the existing folder description
  --overwrite: string@bool-completer # Overwrite only used by the legacy folder implementation
  --title: string # NewTitle it's an optional parameter used for overriding the existing folder title
  --version: int # Version only used by the legacy folder implementation (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_uid)")
  let body = {description: $description, overwrite: $overwrite, title: $title, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete folder.
#
# DELETE /folders/{folder_uid}
# DEPRECATED
# operationId: deleteFolder
@deprecated
export def "folders delete" [
  folder_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceDeleteRules: string@bool-completer # If `true` any Grafana 8 Alerts under this folder will be deleted. Set to `false` so that the request will fail if the folder contains any Grafana 8 Alerts. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceDeleteRules" $forceDeleteRules "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/folders/($folder_uid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the count of each descendant of a folder by kind. The folder is identified by UID.
#
# GET /folders/{folder_uid}/counts
# DEPRECATED
# operationId: getFolderDescendantCounts
@deprecated
export def "folders-counts get" [
  folder_uid: string
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
  let full_url = (build-url $base $"/folders/($folder_uid)/counts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Move folder.
#
# POST /folders/{folder_uid}/move
# DEPRECATED
# operationId: moveFolder
@deprecated
export def "folders-move moveFolder" [
  folder_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentUid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_uid)/move")
  let body = {parentUid: $parentUid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets all existing permissions for the folder with the given `uid`.
#
# GET /folders/{folder_uid}/permissions
# DEPRECATED
# operationId: getFolderPermissionList
@deprecated
export def "folders-permissions get" [
  folder_uid: string
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
  let full_url = (build-url $base $"/folders/($folder_uid)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates permissions for a folder. This operation will remove existing permissions if they’re not included in the request.
#
# POST /folders/{folder_uid}/permissions
# operationId: updateFolderPermissions
# --items item shape: {permission?: int, role?: "None"|"Viewer"|"Editor"|"Admin", teamId?: int, userId?: int}
export def "folders-permissions updateFolderPermissions" [
  folder_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --items: list # item shape: {permission?: int, role?: "None"|"Viewer"|"Editor"|"Admin", teamId?: int, userId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/folders/($folder_uid)/permissions")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# apiHealthHandler will return ok if Grafana's web server is running and it can access the database. If the database cannot be accessed it will return http status code 503.
#
# GET /health
# operationId: getHealth
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiserver: string, commit: string, database: string, enterpriseCommit: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all library elements.
#
# GET /library-elements
# operationId: getLibraryElements
export def "library-elements list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchString: string # Part of the name or description searched for.
  --kind: int@kind-completer # Kind of element to search for. (format: int64)
  --sortDirection: string@sortDirection-completer # Sort order of elements.
  --typeFilter: string # A comma separated list of types to filter the elements by
  --excludeUid: string # Element UID to exclude from search results.
  --folderFilter: string # A comma separated list of folder ID(s) to filter the elements by. Deprecated: Use FolderFilterUIDs instead.
  --folderFilterUIDs: string # A comma separated list of folder UID(s) to filter the elements by.
  --perPage: int # The number of results per page. (format: int64, default: 100)
  --page: int # The page for a set of records, given that only perPage records are returned at a time. Numbering starts at 1. (format: int64, default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchString" $searchString "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "typeFilter" $typeFilter "scalar") (serialize-qp "excludeUid" $excludeUid "scalar") (serialize-qp "folderFilter" $folderFilter "scalar") (serialize-qp "folderFilterUIDs" $folderFilterUIDs "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/library-elements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create library element.
#
# POST /library-elements
# operationId: createLibraryElement
export def "library-elements createLibraryElement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folderId: int # ID of the folder where the library element is stored.  Deprecated: use FolderUID instead (format: int64)
  --folderUid: string # UID of the folder where the library element is stored.
  --kind: int@kind-completer # Kind of element to create, Use 1 for library panels or 2 for c. Description: 1 - library panels (format: int64)
  --model: record # The JSON model for the library element.
  --name: string # Name of the library element.
  --uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/library-elements")
  let body = {folderId: $folderId, folderUid: $folderUid, kind: $kind, model: $model, name: $name, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get library element by name.
#
# GET /library-elements/name/{library_element_name}
# operationId: getLibraryElementByName
export def "library-elements-name get" [
  library_element_name: string
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
  let full_url = (build-url $base $"/library-elements/name/($library_element_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get library element by UID.
#
# GET /library-elements/{library_element_uid}
# operationId: getLibraryElementByUID
export def "library-elements get" [
  library_element_uid: string
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
  let full_url = (build-url $base $"/library-elements/($library_element_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete library element.
#
# DELETE /library-elements/{library_element_uid}
# operationId: deleteLibraryElementByUID
export def "library-elements delete" [
  library_element_uid: string
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
  let full_url = (build-url $base $"/library-elements/($library_element_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update library element.
#
# PATCH /library-elements/{library_element_uid}
# operationId: updateLibraryElement
export def "library-elements updateLibraryElement" [
  library_element_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --folderId: int # ID of the folder where the library element is stored.  Deprecated: use FolderUID instead (format: int64)
  --folderUid: string # UID of the folder where the library element is stored.
  --kind: int@kind-completer # Kind of element to create, Use 1 for library panels or 2 for c. Description: 1 - library panels (format: int64)
  --model: record # The JSON model for the library element.
  --name: string # Name of the library element.
  --uid: string
  --version: int # Version of the library element you are updating. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/library-elements/($library_element_uid)")
  let body = {folderId: $folderId, folderUid: $folderUid, kind: $kind, model: $model, name: $name, uid: $uid, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get library element connections.
#
# GET /library-elements/{library_element_uid}/connections/
# operationId: getLibraryElementConnections
export def "library-elements-connections get" [
  library_element_uid: string
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
  let full_url = (build-url $base $"/library-elements/($library_element_uid)/connections/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check license availability.
#
# GET /licensing/check
# operationId: getStatus
export def "licensing-check get" [
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
  let full_url = (build-url $base "/licensing/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get custom permissions report.
#
# GET /licensing/custom-permissions
# DEPRECATED
# operationId: getCustomPermissionsReport
@deprecated
export def "licensing-custom-permissions get" [
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
  let full_url = (build-url $base "/licensing/custom-permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get custom permissions report in CSV format.
#
# GET /licensing/custom-permissions-csv
# DEPRECATED
# operationId: getCustomPermissionsCSV
@deprecated
export def "licensing-custom-permissions-csv get" [
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
  let full_url = (build-url $base "/licensing/custom-permissions-csv")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh license stats.
#
# GET /licensing/refresh-stats
# operationId: refreshLicenseStats
export def "licensing-refresh-stats refreshLicenseStats" [
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
  let full_url = (build-url $base "/licensing/refresh-stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get license token.
#
# GET /licensing/token
# operationId: getLicenseToken
export def "licensing-token get" [
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
  let full_url = (build-url $base "/licensing/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create license token.
#
# POST /licensing/token
# operationId: postLicenseToken
export def "licensing-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --instance: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensing/token")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove license from database.
#
# DELETE /licensing/token
# operationId: deleteLicenseToken
export def "licensing-token delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --instance: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licensing/token")
  let body = {instance: $instance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manually force license refresh.
#
# POST /licensing/token/renew
# operationId: postRenewLicenseToken
export def "licensing-token-renew post" [
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
  let full_url = (build-url $base "/licensing/token/renew")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GetLogout initiates single logout process.
#
# GET /logout/saml
# operationId: getSAMLLogout
export def "logout-saml get" [
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
  let full_url = (build-url $base "/logout/saml")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current Organization.
#
# GET /org
# operationId: getCurrentOrg
export def "org get" [
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
  let full_url = (build-url $base "/org")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update current Organization.
#
# PUT /org
# operationId: updateCurrentOrg
export def "org updateCurrentOrg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update current Organization's address.
#
# PUT /org/address
# operationId: updateCurrentOrgAddress
export def "org-address updateCurrentOrgAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address1: string
  --address2: string
  --city: string
  --country: string
  --state: string
  --zipcode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/address")
  let body = {address1: $address1, address2: $address2, city: $city, country: $country, state: $state, zipcode: $zipcode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get pending invites.
#
# GET /org/invites
# operationId: getPendingOrgInvites
export def "org-invites get" [
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
  let full_url = (build-url $base "/org/invites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add invite.
#
# POST /org/invites
# operationId: addOrgInvite
export def "org-invites addOrgInvite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loginOrEmail: string
  --name: string
  --role: string@role-completer
  --sendEmail: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/invites")
  let body = {loginOrEmail: $loginOrEmail, name: $name, role: $role, sendEmail: $sendEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke invite.
#
# DELETE /org/invites/{invitation_code}/revoke
# operationId: revokeInvite
export def "org-invites-revoke revokeInvite" [
  invitation_code: string
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
  let full_url = (build-url $base $"/org/invites/($invitation_code)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Current Org Prefs.
#
# GET /org/preferences
# operationId: getOrgPreferences
export def "org-preferences get" [
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
  let full_url = (build-url $base "/org/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Current Org Prefs.
#
# PUT /org/preferences
# operationId: updateOrgPreferences
# --navbar shape: {bookmarkUrls?: list}
# --queryHistory shape: {homeTab?: string}
export def "org-preferences updateOrgPreferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --homeDashboardId: int # The numerical :id of a favorited dashboard (format: int64, default: 0)
  --homeDashboardUID: string
  --language: string
  --navbar: record # shape: {bookmarkUrls?: list}
  --queryHistory: record # shape: {homeTab?: string}
  --theme: string@theme-completer
  --timezone: string # Any IANA timezone string (e.g. America/New_York), 'utc', 'browser', or empty string
  --weekStart: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/preferences")
  let body = {homeDashboardId: $homeDashboardId, homeDashboardUID: $homeDashboardUID, language: $language, navbar: $navbar, queryHistory: $queryHistory, theme: $theme, timezone: $timezone, weekStart: $weekStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch Current Org Prefs.
#
# PATCH /org/preferences
# operationId: patchOrgPreferences
# --navbar shape: {bookmarkUrls?: list}
# --queryHistory shape: {homeTab?: string}
export def "org-preferences patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --homeDashboardId: int # The numerical :id of a favorited dashboard (format: int64, default: 0)
  --homeDashboardUID: string
  --language: string
  --navbar: record # shape: {bookmarkUrls?: list}
  --queryHistory: record # shape: {homeTab?: string}
  --theme: string@theme-completer-1
  --timezone: string # Any IANA timezone string (e.g. America/New_York), 'utc', 'browser', or empty string
  --weekStart: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/preferences")
  let body = {homeDashboardId: $homeDashboardId, homeDashboardUID: $homeDashboardUID, language: $language, navbar: $navbar, queryHistory: $queryHistory, theme: $theme, timezone: $timezone, weekStart: $weekStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Organization quota.
#
# GET /org/quotas
# operationId: getCurrentOrgQuota
export def "org-quotas get" [
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
  let full_url = (build-url $base "/org/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all users within the current organization.
#
# GET /org/users
# operationId: getOrgUsersForCurrentOrg
export def "org-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --limit: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/org/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new user to the current organization.
#
# POST /org/users
# operationId: addOrgUserToCurrentOrg
export def "org-users addOrgUserToCurrentOrg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loginOrEmail: string
  --role: string@role-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/org/users")
  let body = {loginOrEmail: $loginOrEmail, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all users within the current organization (lookup)
#
# GET /org/users/lookup
# operationId: getOrgUsersForCurrentOrgLookup
export def "org-users-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --limit: int # format: int64
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/org/users/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user in current organization.
#
# DELETE /org/users/{user_id}
# operationId: removeOrgUserForCurrentOrg
export def "org-users removeOrgUserForCurrentOrg" [
  user_id: int
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
  let full_url = (build-url $base $"/org/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the given user.
#
# PATCH /org/users/{user_id}
# operationId: updateOrgUserForCurrentOrg
export def "org-users updateOrgUserForCurrentOrg" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/org/users/($user_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search all Organizations.
#
# GET /orgs
# operationId: searchOrgs
export def "orgs searchOrgs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int64, default: 1
  --perpage: int # Number of items per page The totalCount field in the response can be used for pagination list E.g. if totalCount is equal to 100 teams and the perpage parameter is set to 10 then there are 10 pages of teams. (format: int64, default: 1000)
  --name: string
  --qp-query: string # If set it will return results where the query value is contained in the name field. Query values with spaces need to be URL encoded.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perpage" $perpage "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orgs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Organization.
#
# POST /orgs
# operationId: createOrg
export def "orgs createOrg" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orgs")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Organization by Name.
#
# GET /orgs/name/{org_name}
# operationId: getOrgByName
export def "orgs-name get" [
  org_name: string
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
  let full_url = (build-url $base $"/orgs/name/($org_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Organization by ID.
#
# GET /orgs/{org_id}
# operationId: getOrgByID
export def "orgs get" [
  org_id: int
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
  let full_url = (build-url $base $"/orgs/($org_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization.
#
# PUT /orgs/{org_id}
# operationId: updateOrg
export def "orgs updateOrg" [
  org_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Organization.
#
# DELETE /orgs/{org_id}
# operationId: deleteOrgByID
export def "orgs delete" [
  org_id: int
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
  let full_url = (build-url $base $"/orgs/($org_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Organization's address.
#
# PUT /orgs/{org_id}/address
# operationId: updateOrgAddress
export def "orgs-address updateOrgAddress" [
  org_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address1: string
  --address2: string
  --city: string
  --country: string
  --state: string
  --zipcode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org_id)/address")
  let body = {address1: $address1, address2: $address2, city: $city, country: $country, state: $state, zipcode: $zipcode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Organization quota.
#
# GET /orgs/{org_id}/quotas
# operationId: getOrgQuota
export def "orgs-quotas get" [
  org_id: int
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
  let full_url = (build-url $base $"/orgs/($org_id)/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user quota.
#
# PUT /orgs/{org_id}/quotas/{quota_target}
# operationId: updateOrgQuota
export def "orgs-quotas updateOrgQuota" [
  quota_target: string
  org_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int64
  --target: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org_id)/quotas/($quota_target)")
  let body = {limit: $limit, target: $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Users in Organization.
#
# GET /orgs/{org_id}/users
# operationId: getOrgUsers
export def "orgs-users get" [
  org_id: int
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
  let full_url = (build-url $base $"/orgs/($org_id)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new user to the current organization.
#
# POST /orgs/{org_id}/users
# operationId: addOrgUser
export def "orgs-users addOrgUser" [
  org_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loginOrEmail: string
  --role: string@role-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org_id)/users")
  let body = {loginOrEmail: $loginOrEmail, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Users in Organization.
#
# GET /orgs/{org_id}/users/search
# operationId: searchOrgUsers
export def "orgs-users-search searchOrgUsers" [
  org_id: int
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
  let full_url = (build-url $base $"/orgs/($org_id)/users/search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user in current organization.
#
# DELETE /orgs/{org_id}/users/{user_id}
# operationId: removeOrgUser
export def "orgs-users removeOrgUser" [
  org_id: int
  user_id: int
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
  let full_url = (build-url $base $"/orgs/($org_id)/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Users in Organization.
#
# PATCH /orgs/{org_id}/users/{user_id}
# operationId: updateOrgUser
export def "orgs-users updateOrgUser" [
  org_id: int
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string@role-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orgs/($org_id)/users/($user_id)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get playlists.
#
# GET /playlists
# DEPRECATED
# operationId: searchPlaylists
@deprecated
export def "playlists searchPlaylists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --limit: int # in:limit (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create playlist.
#
# POST /playlists
# DEPRECATED
# operationId: createPlaylist
# --items item shape: {Id?: int, PlaylistId?: int, order?: int, title?: string, type?: string, value?: string}
@deprecated
export def "playlists createPlaylist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --interval: string
  --items: list # item shape: {Id?: int, PlaylistId?: int, order?: int, title?: string, type?: string, value?: string}
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/playlists")
  let body = {interval: $interval, items: $items, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get playlist.
#
# GET /playlists/{uid}
# DEPRECATED
# operationId: getPlaylist
@deprecated
export def "playlists get" [
  uid: string
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
  let full_url = (build-url $base $"/playlists/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update playlist.
#
# PUT /playlists/{uid}
# DEPRECATED
# operationId: updatePlaylist
# --items item shape: {Id?: int, PlaylistId?: int, order?: int, title?: string, type?: string, value?: string}
@deprecated
export def "playlists updatePlaylist" [
  uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --interval: string
  --items: list # item shape: {Id?: int, PlaylistId?: int, order?: int, title?: string, type?: string, value?: string}
  --name: string
  --body-uid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/playlists/($uid)")
  let body = {interval: $interval, items: $items, name: $name, uid: $body_uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete playlist.
#
# DELETE /playlists/{uid}
# DEPRECATED
# operationId: deletePlaylist
@deprecated
export def "playlists delete" [
  uid: string
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
  let full_url = (build-url $base $"/playlists/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get playlist items.
#
# GET /playlists/{uid}/items
# DEPRECATED
# operationId: getPlaylistItems
@deprecated
export def "playlists-items get" [
  uid: string
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
  let full_url = (build-url $base $"/playlists/($uid)/items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public dashboard for view
#
# GET /public/dashboards/{accessToken}
# operationId: viewPublicDashboard
export def "public-dashboards viewPublicDashboard" [
  accessToken: string
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
  let full_url = (build-url $base $"/public/dashboards/($accessToken)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get annotations for a public dashboard
#
# GET /public/dashboards/{accessToken}/annotations
# operationId: getPublicAnnotations
export def "public-dashboards-annotations get" [
  accessToken: string
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
  let full_url = (build-url $base $"/public/dashboards/($accessToken)/annotations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get results for a given panel on a public dashboard
#
# POST /public/dashboards/{accessToken}/panels/{panelId}/query
# operationId: queryPublicDashboard
export def "public-dashboards-panels-query queryPublicDashboard" [
  accessToken: string
  panelId: int
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
  let full_url = (build-url $base $"/public/dashboards/($accessToken)/panels/($panelId)/query")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query history search.
#
# GET /query-history
# operationId: searchQueries
export def "query-history searchQueries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --datasourceUid: list # List of data source UIDs to search for
  --searchString: string # Text inside query or comments that is searched for
  --onlyStarred: string@bool-completer # Flag indicating if only starred queries should be returned
  --qp-sort: string@sort-completer # Sort method (default: time-desc)
  --page: int # Use this parameter to access hits beyond limit. Numbering starts at 1. limit param acts as page size. (format: int64)
  --limit: int # Limit the number of returned results (format: int64)
  --qp-from: int # From range for the query history search (format: int64)
  --qp-to: int # To range for the query history search (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasourceUid" $datasourceUid "multi") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "onlyStarred" $onlyStarred "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query-history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add query to query history.
#
# POST /query-history
# operationId: createQuery
export def "query-history createQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --datasourceUid: string # UID of the data source for which are queries stored. (e.g. PE1C5CBDA0504A6A3)
  queries: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/query-history")
  let body = {datasourceUid: $datasourceUid, queries: $queries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add star to query in query history.
#
# POST /query-history/star/{query_history_uid}
# operationId: starQuery
export def "query-history-star starQuery" [
  query_history_uid: string
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
  let full_url = (build-url $base $"/query-history/star/($query_history_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove star to query in query history.
#
# DELETE /query-history/star/{query_history_uid}
# operationId: unstarQuery
export def "query-history-star unstarQuery" [
  query_history_uid: string
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
  let full_url = (build-url $base $"/query-history/star/($query_history_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete query in query history.
#
# DELETE /query-history/{query_history_uid}
# operationId: deleteQuery
export def "query-history delete" [
  query_history_uid: string
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
  let full_url = (build-url $base $"/query-history/($query_history_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update comment for query in query history.
#
# PATCH /query-history/{query_history_uid}
# operationId: patchQueryComment
export def "query-history patch" [
  query_history_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # Updated comment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/query-history/($query_history_uid)")
  let body = {comment: $comment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all rules in the database: active or deleted.
#
# GET /recording-rules
# operationId: listRecordingRules
export def "recording-rules listRecordingRules" [
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
  let full_url = (build-url $base "/recording-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the active status of a rule.
#
# PUT /recording-rules
# operationId: updateRecordingRule
export def "recording-rules updateRecordingRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
  --count: string@bool-completer
  --description: string
  --dest-data-source-uid: string
  --id: string
  --interval: int # format: int64
  --name: string
  --prom-name: string
  --queries: list
  --range: int # format: int64
  --target-ref-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recording-rules")
  let body = {active: $active, count: $count, description: $description, dest_data_source_uid: $dest_data_source_uid, id: $id, interval: $interval, name: $name, prom_name: $prom_name, queries: $queries, range: $range, target_ref_id: $target_ref_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a recording rule that is then registered and started.
#
# POST /recording-rules
# operationId: createRecordingRule
export def "recording-rules createRecordingRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
  --count: string@bool-completer
  --description: string
  --dest-data-source-uid: string
  --id: string
  --interval: int # format: int64
  --name: string
  --prom-name: string
  --queries: list
  --range: int # format: int64
  --target-ref-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recording-rules")
  let body = {active: $active, count: $count, description: $description, dest_data_source_uid: $dest_data_source_uid, id: $id, interval: $interval, name: $name, prom_name: $prom_name, queries: $queries, range: $range, target_ref_id: $target_ref_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test a recording rule.
#
# POST /recording-rules/test
# operationId: testCreateRecordingRule
export def "recording-rules-test testCreateRecordingRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer
  --count: string@bool-completer
  --description: string
  --dest-data-source-uid: string
  --id: string
  --interval: int # format: int64
  --name: string
  --prom-name: string
  --queries: list
  --range: int # format: int64
  --target-ref-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recording-rules/test")
  let body = {active: $active, count: $count, description: $description, dest_data_source_uid: $dest_data_source_uid, id: $id, interval: $interval, name: $name, prom_name: $prom_name, queries: $queries, range: $range, target_ref_id: $target_ref_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return the prometheus remote write target.
#
# GET /recording-rules/writer
# operationId: getRecordingRuleWriteTarget
export def "recording-rules-writer get" [
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
  let full_url = (build-url $base "/recording-rules/writer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a remote write target.
#
# POST /recording-rules/writer
# operationId: createRecordingRuleWriteTarget
export def "recording-rules-writer createRecordingRuleWriteTarget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data-source-uid: string
  --id: string
  --remote-write-path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recording-rules/writer")
  let body = {data_source_uid: $data_source_uid, id: $id, remote_write_path: $remote_write_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the remote write target.
#
# DELETE /recording-rules/writer
# operationId: deleteRecordingRuleWriteTarget
export def "recording-rules-writer delete" [
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
  let full_url = (build-url $base "/recording-rules/writer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete removes the rule from the registry and stops it.
#
# DELETE /recording-rules/{recordingRuleID}
# operationId: deleteRecordingRule
export def "recording-rules delete" [
  recordingRuleID: int
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
  let full_url = (build-url $base $"/recording-rules/($recordingRuleID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List reports.
#
# GET /reports
# operationId: getReports
export def "reports list" [
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
  let full_url = (build-url $base "/reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a report.
#
# POST /reports
# operationId: createReport
# --dashboards item shape: {dashboard?: record, reportVariables?: record, timeRange?: record}
# --options shape: {csvEncoding?: string, layout?: string, orientation?: string, pdfCombineOneFile?: bool, pdfShowTemplateVariables?: bool, timeRange?: record}
# --schedule shape: {dayOfMonth?: string, endDate?: string, frequency?: string, intervalAmount?: int, intervalFrequency?: string, startDate?: string, timeZone?: string, workdaysOnly?: bool}
# --urls item shape: {title?: string, url?: string}
export def "reports createReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboards: list # item shape: {dashboard?: record, reportVariables?: record, timeRange?: record}
  --enableCsv: string@bool-completer
  --enableDashboardUrl: string@bool-completer
  --formats: list
  --message: string
  --name: string
  --options: record # shape: {csvEncoding?: string, layout?: string, orientation?: string, pdfCombineOneFile?: bool, pdfShowTemplateVariables?: bool, timeRange?: record}
  --recipients: string
  --replyTo: string
  --scaleFactor: int # format: int64
  --schedule: record # shape: {dayOfMonth?: string, endDate?: string, frequency?: string, intervalAmount?: int, intervalFrequency?: string, startDate?: string, timeZone?: string, workdaysOnly?: bool}
  --state: string # +enum
  --subject: string
  --urls: list # item shape: {title?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports")
  let body = {dashboards: $dashboards, enableCsv: $enableCsv, enableDashboardUrl: $enableDashboardUrl, formats: $formats, message: $message, name: $name, options: $options, recipients: $recipients, replyTo: $replyTo, scaleFactor: $scaleFactor, schedule: $schedule, state: $state, subject: $subject, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List reports by dashboard uid.
#
# GET /reports/dashboards/{uid}
# operationId: getReportsByDashboardUID
export def "reports-dashboards get" [
  uid: string
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
  let full_url = (build-url $base $"/reports/dashboards/($uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a report.
#
# POST /reports/email
# operationId: sendReport
export def "reports-email sendReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emails: string # Comma-separated list of emails to which to send the report to.
  --id: string # Send the report to the emails specified in the report. Required if emails is not present. (format: int64)
  --useEmailsFromReport: string@bool-completer # Send the report to the emails specified in the report. Required if emails is not present.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/email")
  let body = {emails: $emails, id: $id, useEmailsFromReport: $useEmailsFromReport} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get custom branding report image.
#
# GET /reports/images/:image
# operationId: getSettingsImage
export def "reports-images-image get" [
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
  let full_url = (build-url $base "/reports/images/:image")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a CSV report.
#
# GET /reports/render/csvs
# operationId: renderReportCSVs
export def "reports-render-csvs renderReportCSVs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboards: string
  --title: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dashboards" $dashboards "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/render/csvs" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Render report for multiple dashboards.
#
# GET /reports/render/pdfs
# operationId: renderReportPDFs
export def "reports-render-pdfs renderReportPDFs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboards: string
  --orientation: string
  --layout: string
  --title: string
  --scaleFactor: string
  --includeTables: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dashboards" $dashboards "scalar") (serialize-qp "orientation" $orientation "scalar") (serialize-qp "layout" $layout "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "scaleFactor" $scaleFactor "scalar") (serialize-qp "includeTables" $includeTables "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/render/pdfs" $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get report settings.
#
# GET /reports/settings
# operationId: getReportSettings
export def "reports-settings get" [
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
  let full_url = (build-url $base "/reports/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save settings.
#
# POST /reports/settings
# operationId: saveReportSettings
# --branding shape: {emailFooterLink?: string, emailFooterMode?: string, emailFooterText?: string, emailLogoUrl?: string, reportLogoUrl?: string}
# --footerItems item shape: {color?: string, fontSize?: string, fontStyle?: string, fontWeight?: string, type?: string, value?: string}
export def "reports-settings saveReportSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --branding: record # shape: {emailFooterLink?: string, emailFooterMode?: string, emailFooterText?: string, emailLogoUrl?: string, reportLogoUrl?: string}
  --embeddedImageTheme: string
  --footerFontFamily: string
  --footerItems: list # item shape: {color?: string, fontSize?: string, fontStyle?: string, fontWeight?: string, type?: string, value?: string}
  --id: int # format: int64
  --orgId: int # format: int64
  --pdfDashboardTitleEnabled: string@bool-completer
  --pdfHeaderEnabled: string@bool-completer
  --pdfTheme: string
  --pdfTimeRangeEnabled: string@bool-completer
  --userId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/settings")
  let body = {branding: $branding, embeddedImageTheme: $embeddedImageTheme, footerFontFamily: $footerFontFamily, footerItems: $footerItems, id: $id, orgId: $orgId, pdfDashboardTitleEnabled: $pdfDashboardTitleEnabled, pdfHeaderEnabled: $pdfHeaderEnabled, pdfTheme: $pdfTheme, pdfTimeRangeEnabled: $pdfTimeRangeEnabled, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send test report via email.
#
# POST /reports/test-email
# operationId: sendTestEmail
# --dashboards item shape: {dashboard?: record, reportVariables?: record, timeRange?: record}
# --options shape: {csvEncoding?: string, layout?: string, orientation?: string, pdfCombineOneFile?: bool, pdfShowTemplateVariables?: bool, timeRange?: record}
# --schedule shape: {dayOfMonth?: string, endDate?: string, frequency?: string, intervalAmount?: int, intervalFrequency?: string, startDate?: string, timeZone?: string, workdaysOnly?: bool}
# --urls item shape: {title?: string, url?: string}
export def "reports-test-email sendTestEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboards: list # item shape: {dashboard?: record, reportVariables?: record, timeRange?: record}
  --enableCsv: string@bool-completer
  --enableDashboardUrl: string@bool-completer
  --formats: list
  --message: string
  --name: string
  --options: record # shape: {csvEncoding?: string, layout?: string, orientation?: string, pdfCombineOneFile?: bool, pdfShowTemplateVariables?: bool, timeRange?: record}
  --recipients: string
  --replyTo: string
  --scaleFactor: int # format: int64
  --schedule: record # shape: {dayOfMonth?: string, endDate?: string, frequency?: string, intervalAmount?: int, intervalFrequency?: string, startDate?: string, timeZone?: string, workdaysOnly?: bool}
  --state: string # +enum
  --subject: string
  --urls: list # item shape: {title?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/test-email")
  let body = {dashboards: $dashboards, enableCsv: $enableCsv, enableDashboardUrl: $enableDashboardUrl, formats: $formats, message: $message, name: $name, options: $options, recipients: $recipients, replyTo: $replyTo, scaleFactor: $scaleFactor, schedule: $schedule, state: $state, subject: $subject, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a report.
#
# GET /reports/{id}
# DEPRECATED
# operationId: getReport
@deprecated
export def "reports get" [
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
  let full_url = (build-url $base $"/reports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a report.
#
# PUT /reports/{id}
# DEPRECATED
# operationId: updateReport
# --dashboards item shape: {dashboard?: record, reportVariables?: record, timeRange?: record}
# --options shape: {csvEncoding?: string, layout?: string, orientation?: string, pdfCombineOneFile?: bool, pdfShowTemplateVariables?: bool, timeRange?: record}
# --schedule shape: {dayOfMonth?: string, endDate?: string, frequency?: string, intervalAmount?: int, intervalFrequency?: string, startDate?: string, timeZone?: string, workdaysOnly?: bool}
# --urls item shape: {title?: string, url?: string}
@deprecated
export def "reports updateReport" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dashboards: list # item shape: {dashboard?: record, reportVariables?: record, timeRange?: record}
  --enableCsv: string@bool-completer
  --enableDashboardUrl: string@bool-completer
  --formats: list
  --message: string
  --name: string
  --options: record # shape: {csvEncoding?: string, layout?: string, orientation?: string, pdfCombineOneFile?: bool, pdfShowTemplateVariables?: bool, timeRange?: record}
  --recipients: string
  --replyTo: string
  --scaleFactor: int # format: int64
  --schedule: record # shape: {dayOfMonth?: string, endDate?: string, frequency?: string, intervalAmount?: int, intervalFrequency?: string, startDate?: string, timeZone?: string, workdaysOnly?: bool}
  --state: string # +enum
  --subject: string
  --urls: list # item shape: {title?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/($id)")
  let body = {dashboards: $dashboards, enableCsv: $enableCsv, enableDashboardUrl: $enableDashboardUrl, formats: $formats, message: $message, name: $name, options: $options, recipients: $recipients, replyTo: $replyTo, scaleFactor: $scaleFactor, schedule: $schedule, state: $state, subject: $subject, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a report.
#
# DELETE /reports/{id}
# DEPRECATED
# operationId: deleteReport
@deprecated
export def "reports delete" [
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
  let full_url = (build-url $base $"/reports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# It performs Assertion Consumer Service (ACS).
#
# POST /saml/acs
# operationId: postACS
export def "saml-acs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RelayState: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RelayState" $RelayState "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/saml/acs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# It exposes the SP (Grafana's) metadata for the IdP's consumption.
#
# GET /saml/metadata
# operationId: getMetadata
export def "saml-metadata get" [
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
  let full_url = (build-url $base "/saml/metadata")
  let accept_val = "application/xml;application/samlmetadata+xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# It performs Single Logout (SLO) callback.
#
# GET /saml/slo
# operationId: getSLO
export def "saml-slo get" [
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
  let full_url = (build-url $base "/saml/slo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# It performs Single Logout (SLO) callback.
#
# POST /saml/slo
# operationId: postSLO
export def "saml-slo post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SAMLRequest: string
  --SAMLResponse: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SAMLRequest" $SAMLRequest "scalar") (serialize-qp "SAMLResponse" $SAMLResponse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/saml/slo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /search
#
# operationId: search
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search Query
  --tag: list # List of tags to search for
  --type: string@type-completer-1 # Type to search for, dash-folder or dash-db
  --dashboardIds: list # List of dashboard id’s to search for This is deprecated: users should use the `dashboardUIDs` query parameter instead
  --dashboardUIDs: list # List of dashboard uid’s to search for
  --folderIds: list # List of folder id’s to search in for dashboards If it's `0` then it will query for the top level folders This is deprecated: users should use the `folderUIDs` query parameter instead
  --folderUIDs: list # List of folder UID’s to search in for dashboards If it's an empty string then it will query for the top level folders
  --starred: string@bool-completer # Flag indicating if only starred Dashboards should be returned
  --limit: int # Limit the number of returned results (max 5000) (format: int64)
  --page: int # Use this parameter to access hits beyond limit. Numbering starts at 1. limit param acts as page size. Only available in Grafana v6.2+. (format: int64)
  --permission: string@permission-completer # Set to `Edit` to return dashboards/folders that the user can edit (default: View)
  --qp-sort: string@sort-completer-1 # Sort method; for listing all the possible sort methods use the search sorting endpoint. (default: alpha-asc)
  --deleted: string@bool-completer # Flag indicating if only soft deleted Dashboards should be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "tag" $tag "multi") (serialize-qp "type" $type "scalar") (serialize-qp "dashboardIds" $dashboardIds "csv") (serialize-qp "dashboardUIDs" $dashboardUIDs "csv") (serialize-qp "folderIds" $folderIds "csv") (serialize-qp "folderUIDs" $folderUIDs "csv") (serialize-qp "starred" $starred "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "permission" $permission "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List search sorting options.
#
# GET /search/sorting
# operationId: listSortOptions
export def "search-sorting listSortOptions" [
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
  let full_url = (build-url $base "/search/sorting")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create service account
#
# POST /serviceaccounts
# operationId: createServiceAccount
export def "serviceaccounts createServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isDisabled: string@bool-completer # e.g. false
  --name: string # e.g. grafana
  --role: string@role-completer # e.g. Admin
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/serviceaccounts")
  let body = {isDisabled: $isDisabled, name: $name, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search service accounts with paging
#
# GET /serviceaccounts/search
# operationId: searchOrgServiceAccountsWithPaging
export def "serviceaccounts-search searchOrgServiceAccountsWithPaging" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Disabled: string@bool-completer
  --expiredTokens: string@bool-completer
  --qp-query: string # It will return results where the query value is contained in one of the name. Query values with spaces need to be URL encoded.
  --perpage: int # The default value is 1000. (format: int64)
  --page: int # The default value is 1. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Disabled" $Disabled "scalar") (serialize-qp "expiredTokens" $expiredTokens "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "perpage" $perpage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/serviceaccounts/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get single serviceaccount by Id
#
# GET /serviceaccounts/{serviceAccountId}
# operationId: retrieveServiceAccount
export def "serviceaccounts retrieveServiceAccount" [
  serviceAccountId: int
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
  let full_url = (build-url $base $"/serviceaccounts/($serviceAccountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete service account
#
# DELETE /serviceaccounts/{serviceAccountId}
# operationId: deleteServiceAccount
export def "serviceaccounts delete" [
  serviceAccountId: int
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
  let full_url = (build-url $base $"/serviceaccounts/($serviceAccountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update service account
#
# PATCH /serviceaccounts/{serviceAccountId}
# operationId: updateServiceAccount
export def "serviceaccounts updateServiceAccount" [
  serviceAccountId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isDisabled: string@bool-completer
  --name: string
  --role: string@role-completer
  --body-serviceAccountId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/serviceaccounts/($serviceAccountId)")
  let body = {isDisabled: $isDisabled, name: $name, role: $role, serviceAccountId: $body_serviceAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get service account tokens
#
# GET /serviceaccounts/{serviceAccountId}/tokens
# operationId: listTokens
export def "serviceaccounts-tokens listTokens" [
  serviceAccountId: int
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
  let full_url = (build-url $base $"/serviceaccounts/($serviceAccountId)/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# CreateNewToken adds a token to a service account
#
# POST /serviceaccounts/{serviceAccountId}/tokens
# operationId: createToken
export def "serviceaccounts-tokens createToken" [
  serviceAccountId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --secondsToLive: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/serviceaccounts/($serviceAccountId)/tokens")
  let body = {name: $name, secondsToLive: $secondsToLive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DeleteToken deletes service account tokens
#
# DELETE /serviceaccounts/{serviceAccountId}/tokens/{tokenId}
# operationId: deleteToken
export def "serviceaccounts-tokens delete" [
  tokenId: int
  serviceAccountId: int
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
  let full_url = (build-url $base $"/serviceaccounts/($serviceAccountId)/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get JSON Web Key Set (JWKS) with all the keys that can be used to verify tokens (public keys)
#
# GET /signing-keys/keys
# operationId: retrieveJWKS
export def "signing-keys-keys retrieveJWKS" [
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
  let full_url = (build-url $base "/signing-keys/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get snapshot sharing settings.
#
# GET /snapshot/shared-options
# operationId: getSharingOptions
export def "snapshot-shared-options get" [
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
  let full_url = (build-url $base "/snapshot/shared-options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# When creating a snapshot using the API, you have to provide the full dashboard payload including the snapshot data. This endpoint is designed for the Grafana UI.
#
# POST /snapshots
# operationId: createDashboardSnapshot
# --dashboard shape: {Object?: record}
export def "snapshots createDashboardSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apiVersion: string # APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources +optional
  dashboard: record # Unstructured allows objects that do not have Golang structs registered to be manipulated generically. — shape: {Object?: record}
  --deleteKey: string # Unique key used to delete the snapshot. It is different from the `key` so that only the creator can delete the snapshot. Required if `external` is `true`.
  --expires: int # When the snapshot should expire in seconds in seconds. Default is never to expire. (format: int64, default: 0)
  --external: string@bool-completer # these are passed when storing an external snapshot ref Save the snapshot on an external server rather than locally. (default: false)
  --key: string # Define the unique key. Required if `external` is `true`.
  --kind: string # Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds +optional
  --name: string # Snapshot name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snapshots")
  let body = {apiVersion: $apiVersion, dashboard: $dashboard, deleteKey: $deleteKey, expires: $expires, external: $external, key: $key, kind: $kind, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Snapshot by deleteKey.
#
# GET /snapshots-delete/{deleteKey}
# operationId: deleteDashboardSnapshotByDeleteKey
export def "snapshots-delete get" [
  deleteKey: string
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
  let full_url = (build-url $base $"/snapshots-delete/($deleteKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Snapshot by Key.
#
# GET /snapshots/{key}
# operationId: getDashboardSnapshot
export def "snapshots get" [
  key: string
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
  let full_url = (build-url $base $"/snapshots/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Snapshot by Key.
#
# DELETE /snapshots/{key}
# operationId: deleteDashboardSnapshot
export def "snapshots delete" [
  key: string
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
  let full_url = (build-url $base $"/snapshots/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Team.
#
# POST /teams
# operationId: createTeam
export def "teams createTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teams")
  let body = {email: $email, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Team Search With Paging.
#
# GET /teams/search
# operationId: searchTeams
export def "teams-search searchTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int64, default: 1
  --perpage: int # Number of items per page The totalCount field in the response can be used for pagination list E.g. if totalCount is equal to 100 teams and the perpage parameter is set to 10 then there are 10 pages of teams. (format: int64, default: 1000)
  --name: string
  --qp-query: string # If set it will return results where the query value is contained in the name field. Query values with spaces need to be URL encoded.
  --accesscontrol: string@bool-completer # default: false
  --qp-sort: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perpage" $perpage "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "accesscontrol" $accesscontrol "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get External Groups.
#
# GET /teams/{teamId}/groups
# operationId: getTeamGroupsApi
export def "teams-groups get" [
  teamId: string
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
  let full_url = (build-url $base $"/teams/($teamId)/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add External Group.
#
# POST /teams/{teamId}/groups
# operationId: addTeamGroupApi
export def "teams-groups addTeamGroupApi" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($teamId)/groups")
  let body = {groupId: $groupId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove External Group.
#
# DELETE /teams/{teamId}/groups
# operationId: removeTeamGroupApiQuery
export def "teams-groups removeTeamGroupApiQuery" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for team groups with optional filtering and pagination.
#
# GET /teams/{teamId}/groups/search
# operationId: searchTeamGroups
export def "teams-groups-search searchTeamGroups" [
  teamId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int64, default: 1
  --perpage: int # Number of items per page (format: int64, default: 1000)
  --qp-query: string # If set it will return results where the query value is contained in the name field. Query values with spaces need to be URL encoded.
  --name: string # Filter by exact name match
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perpage" $perpage "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($teamId)/groups/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team By ID.
#
# GET /teams/{team_id}
# operationId: getTeamByID
export def "teams get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accesscontrol: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accesscontrol" $accesscontrol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/teams/($team_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team.
#
# PUT /teams/{team_id}
# operationId: updateTeam
export def "teams updateTeam" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)")
  let body = {email: $email, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Team By ID.
#
# DELETE /teams/{team_id}
# operationId: deleteTeamByID
export def "teams delete" [
  team_id: string
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
  let full_url = (build-url $base $"/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team Members.
#
# GET /teams/{team_id}/members
# operationId: getTeamMembers
export def "teams-members get" [
  team_id: string
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
  let full_url = (build-url $base $"/teams/($team_id)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set team memberships.
#
# PUT /teams/{team_id}/members
# operationId: setTeamMemberships
export def "teams-members setTeamMemberships" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --admins: list
  --members: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)/members")
  let body = {admins: $admins, members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Team Member.
#
# POST /teams/{team_id}/members
# operationId: addTeamMember
export def "teams-members addTeamMember" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)/members")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Team Member.
#
# PUT /teams/{team_id}/members/{user_id}
# operationId: updateTeamMember
export def "teams-members updateTeamMember" [
  team_id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permission: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)/members/($user_id)")
  let body = {permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Member From Team.
#
# DELETE /teams/{team_id}/members/{user_id}
# operationId: removeTeamMember
export def "teams-members removeTeamMember" [
  team_id: string
  user_id: int
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
  let full_url = (build-url $base $"/teams/($team_id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team Preferences.
#
# GET /teams/{team_id}/preferences
# operationId: getTeamPreferences
export def "teams-preferences get" [
  team_id: string
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
  let full_url = (build-url $base $"/teams/($team_id)/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team Preferences.
#
# PUT /teams/{team_id}/preferences
# operationId: updateTeamPreferences
# --navbar shape: {bookmarkUrls?: list}
# --queryHistory shape: {homeTab?: string}
export def "teams-preferences updateTeamPreferences" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --homeDashboardId: int # The numerical :id of a favorited dashboard (format: int64, default: 0)
  --homeDashboardUID: string
  --language: string
  --navbar: record # shape: {bookmarkUrls?: list}
  --queryHistory: record # shape: {homeTab?: string}
  --theme: string@theme-completer
  --timezone: string # Any IANA timezone string (e.g. America/New_York), 'utc', 'browser', or empty string
  --weekStart: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)/preferences")
  let body = {homeDashboardId: $homeDashboardId, homeDashboardUID: $homeDashboardUID, language: $language, navbar: $navbar, queryHistory: $queryHistory, theme: $theme, timezone: $timezone, weekStart: $weekStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get (current authenticated user)
#
# GET /user
# operationId: getSignedInUser
export def "user get" [
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

# Update signed in User.
#
# PUT /user
# operationId: updateSignedInUser
export def "user updateSignedInUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --login: string
  --name: string
  --theme: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let body = {email: $email, login: $login, name: $name, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Auth tokens of the actual User.
#
# GET /user/auth-tokens
# operationId: getUserAuthTokens
export def "user-auth-tokens get" [
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
  let full_url = (build-url $base "/user/auth-tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user email.
#
# GET /user/email/update
# operationId: updateUserEmail
export def "user-email-update updateUserEmail" [
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
  let full_url = (build-url $base "/user/email/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Organizations of the actual User.
#
# GET /user/orgs
# operationId: getSignedInUserOrgList
export def "user-orgs get" [
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
  let full_url = (build-url $base "/user/orgs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Password.
#
# PUT /user/password
# operationId: changeUserPassword
export def "user-password changeUserPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newPassword: string
  --oldPassword: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/password")
  let body = {newPassword: $newPassword, oldPassword: $oldPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get user preferences.
#
# GET /user/preferences
# operationId: getUserPreferences
export def "user-preferences get" [
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
  let full_url = (build-url $base "/user/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user preferences.
#
# PUT /user/preferences
# operationId: updateUserPreferences
# --navbar shape: {bookmarkUrls?: list}
# --queryHistory shape: {homeTab?: string}
export def "user-preferences updateUserPreferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --homeDashboardId: int # The numerical :id of a favorited dashboard (format: int64, default: 0)
  --homeDashboardUID: string
  --language: string
  --navbar: record # shape: {bookmarkUrls?: list}
  --queryHistory: record # shape: {homeTab?: string}
  --theme: string@theme-completer
  --timezone: string # Any IANA timezone string (e.g. America/New_York), 'utc', 'browser', or empty string
  --weekStart: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/preferences")
  let body = {homeDashboardId: $homeDashboardId, homeDashboardUID: $homeDashboardUID, language: $language, navbar: $navbar, queryHistory: $queryHistory, theme: $theme, timezone: $timezone, weekStart: $weekStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch user preferences.
#
# PATCH /user/preferences
# operationId: patchUserPreferences
# --navbar shape: {bookmarkUrls?: list}
# --queryHistory shape: {homeTab?: string}
export def "user-preferences patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --homeDashboardId: int # The numerical :id of a favorited dashboard (format: int64, default: 0)
  --homeDashboardUID: string
  --language: string
  --navbar: record # shape: {bookmarkUrls?: list}
  --queryHistory: record # shape: {homeTab?: string}
  --theme: string@theme-completer-1
  --timezone: string # Any IANA timezone string (e.g. America/New_York), 'utc', 'browser', or empty string
  --weekStart: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/preferences")
  let body = {homeDashboardId: $homeDashboardId, homeDashboardUID: $homeDashboardUID, language: $language, navbar: $navbar, queryHistory: $queryHistory, theme: $theme, timezone: $timezone, weekStart: $weekStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch user quota.
#
# GET /user/quotas
# operationId: getUserQuotas
export def "user-quotas get" [
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
  let full_url = (build-url $base "/user/quotas")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke an auth token of the actual User.
#
# POST /user/revoke-auth-token
# operationId: revokeUserAuthToken
export def "user-revoke-auth-token revokeUserAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authTokenId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/revoke-auth-token")
  let body = {authTokenId: $authTokenId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Star a dashboard.
#
# POST /user/stars/dashboard/uid/{dashboard_uid}
# operationId: starDashboardByUID
export def "user-stars-dashboard-uid starDashboardByUID" [
  dashboard_uid: string
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
  let full_url = (build-url $base $"/user/stars/dashboard/uid/($dashboard_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unstar a dashboard.
#
# DELETE /user/stars/dashboard/uid/{dashboard_uid}
# operationId: unstarDashboardByUID
export def "user-stars-dashboard-uid unstarDashboardByUID" [
  dashboard_uid: string
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
  let full_url = (build-url $base $"/user/stars/dashboard/uid/($dashboard_uid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Teams that the actual User is member of.
#
# GET /user/teams
# operationId: getSignedInUserTeamList
export def "user-teams get" [
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
  let full_url = (build-url $base "/user/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Switch user context for signed in user.
#
# POST /user/using/{org_id}
# operationId: userSetUsingOrg
export def "user-using userSetUsingOrg" [
  org_id: int
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
  let full_url = (build-url $base $"/user/using/($org_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users.
#
# GET /users
# operationId: searchUsers
export def "users searchUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perpage: int # Limit the maximum number of users to return per page (format: int64, default: 1000)
  --page: int # Page index for starting fetching users (format: int64, default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perpage" $perpage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user by login or email.
#
# GET /users/lookup
# operationId: getUserByLoginOrEmail
export def "users-lookup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loginOrEmail: string # loginOrEmail of the user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loginOrEmail" $loginOrEmail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get users with paging.
#
# GET /users/search
# operationId: searchUsersWithPaging
export def "users-search searchUsersWithPaging" [
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
  let full_url = (build-url $base "/users/search")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user by id.
#
# GET /users/{user_id}
# operationId: getUserByID
export def "users get" [
  user_id: int
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
  let full_url = (build-url $base $"/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user.
#
# PUT /users/{user_id}
# operationId: updateUser
export def "users updateUser" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --login: string
  --name: string
  --theme: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let body = {email: $email, login: $login, name: $name, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get organizations for user.
#
# GET /users/{user_id}/orgs
# operationId: getUserOrgList
export def "users-orgs get" [
  user_id: int
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
  let full_url = (build-url $base $"/users/($user_id)/orgs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get teams for user.
#
# GET /users/{user_id}/teams
# operationId: getUserTeams
export def "users-teams get" [
  user_id: int
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
  let full_url = (build-url $base $"/users/($user_id)/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the alert rules.
#
# GET /v1/provisioning/alert-rules
# DEPRECATED
# operationId: RouteGetAlertRules
@deprecated
export def "provisioning-alert-rules RouteGetAlertRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<annotations: record, condition: string, data: list<record>, execErrState: string, folderUID: string, for: string, id: int, isPaused: bool, keep_firing_for: string, labels: record, missingSeriesEvalsToResolve: int, noDataState: string, notification_settings: record<active_time_intervals: list, group_by: list, group_interval: string, group_wait: string, mute_time_intervals: list, receiver: string, repeat_interval: string>, orgID: int, provenance: string, record: record<from: string, metric: string, target_datasource_uid: string>, ruleGroup: string, title: string, uid: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/alert-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new alert rule.
#
# POST /v1/provisioning/alert-rules
# DEPRECATED
# operationId: RoutePostAlertRule
# --data item shape: {datasourceUid?: string, model?: record, queryType?: string, refId?: string, relativeTimeRange?: record}
# --notification_settings shape: {active_time_intervals?: list, group_by?: list, group_interval?: string, group_wait?: string, mute_time_intervals?: list, receiver: string, repeat_interval?: string}
# --record shape: {from: string, metric: string, target_datasource_uid?: string}
@deprecated
export def "provisioning-alert-rules RoutePostAlertRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --annotations: record # e.g. {runbook_url: https://supercoolrunbook.com/page/13}
  condition: string # e.g. A
  data: list # e.g. [{datasourceUid: __expr__, model: {conditions: [{evaluator: {params: [0, 0], type: gt}, operator: {type: and}, query: {params: []}, reducer: {params: [], type: avg}, type: query}], datasource: {type: __expr__, uid: __expr__}, expression: 1 == 1, hide: false, intervalMs: 1000, maxDataPoints: 43200, refId: A, type: math}, queryType: , refId: A, relativeTimeRange: {from: 0, to: 0}}] — item shape: {datasourceUid?: string, model?: record, queryType?: string, refId?: string, relativeTimeRange?: record}
  execErrState: string@execErrState-completer
  folderUID: string # e.g. project_x
  --body-for: string # format: duration
  --id: int # format: int64
  --isPaused: string@bool-completer # e.g. false
  --keep-firing-for: string # format: duration
  --labels: record # e.g. {team: sre-team-1}
  --missingSeriesEvalsToResolve: int # format: int64, e.g. 2
  noDataState: string@noDataState-completer
  --notification-settings: record # shape: {active_time_intervals?: list, group_by?: list, group_interval?: string, group_wait?: string, mute_time_intervals?: list, receiver: string, repeat_interval?: string}
  orgID: int # format: int64
  --provenance: string
  --record: record # shape: {from: string, metric: string, target_datasource_uid?: string}
  ruleGroup: string # e.g. eval_group_1
  title: string # e.g. Always firing
  --uid: string
]: any -> record<annotations: record, condition: string, data: table<datasourceUid: string, model: record, queryType: string, refId: string, relativeTimeRange: record>, execErrState: string, folderUID: string, for: string, id: int, isPaused: bool, keep_firing_for: string, labels: record, missingSeriesEvalsToResolve: int, noDataState: string, notification_settings: record<active_time_intervals: list<string>, group_by: list<string>, group_interval: string, group_wait: string, mute_time_intervals: list<string>, receiver: string, repeat_interval: string>, orgID: int, provenance: string, record: record<from: string, metric: string, target_datasource_uid: string>, ruleGroup: string, title: string, uid: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/alert-rules")
  let body = {annotations: $annotations, condition: $condition, data: $data, execErrState: $execErrState, folderUID: $folderUID, for: $body_for, id: $id, isPaused: $isPaused, keep_firing_for: $keep_firing_for, labels: $labels, missingSeriesEvalsToResolve: $missingSeriesEvalsToResolve, noDataState: $noDataState, notification_settings: $notification_settings, orgID: $orgID, provenance: $provenance, record: $record, ruleGroup: $ruleGroup, title: $title, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export all alert rules in provisioning file format.
#
# GET /v1/provisioning/alert-rules/export
# operationId: RouteGetAlertRulesExport
export def "provisioning-alert-rules-export RouteGetAlertRulesExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --download: string@bool-completer # Whether to initiate a download of the file or not. (default: false)
  --format: string@format-completer # Format of the downloaded file. Supported yaml, json or hcl. Accept header can also be used, but the query parameter will take precedence. (default: yaml)
  --folderUid: list # UIDs of folders from which to export rules
  --group: string # Name of group of rules to export. Must be specified only together with a single folder UID
  --ruleUid: string # UID of alert rule to export. If specified, parameters folderUid and group must be empty.
]: nothing -> record<apiVersion: int, contactPoints: table<name: string, orgId: int, receivers: list>, groups: table<folder: string, interval: int, name: string, orgId: int, rules: list>, muteTimes: table<name: string, orgId: int, time_intervals: list>, policies: table<active_time_intervals: list, continue: bool, group_by: list, group_interval: string, group_wait: string, match: record, match_re: record, matchers: list, mute_time_intervals: list, object_matchers: list, orgId: int, receiver: string, repeat_interval: string, routes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "folderUid" $folderUid "csv") (serialize-qp "group" $group "scalar") (serialize-qp "ruleUid" $ruleUid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/provisioning/alert-rules/export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific alert rule by UID.
#
# GET /v1/provisioning/alert-rules/{UID}
# DEPRECATED
# operationId: RouteGetAlertRule
@deprecated
export def "provisioning-alert-rules RouteGetAlertRule" [
  UID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<annotations: record, condition: string, data: table<datasourceUid: string, model: record, queryType: string, refId: string, relativeTimeRange: record>, execErrState: string, folderUID: string, for: string, id: int, isPaused: bool, keep_firing_for: string, labels: record, missingSeriesEvalsToResolve: int, noDataState: string, notification_settings: record<active_time_intervals: list<string>, group_by: list<string>, group_interval: string, group_wait: string, mute_time_intervals: list<string>, receiver: string, repeat_interval: string>, orgID: int, provenance: string, record: record<from: string, metric: string, target_datasource_uid: string>, ruleGroup: string, title: string, uid: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/alert-rules/($UID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing alert rule.
#
# PUT /v1/provisioning/alert-rules/{UID}
# DEPRECATED
# operationId: RoutePutAlertRule
# --data item shape: {datasourceUid?: string, model?: record, queryType?: string, refId?: string, relativeTimeRange?: record}
# --notification_settings shape: {active_time_intervals?: list, group_by?: list, group_interval?: string, group_wait?: string, mute_time_intervals?: list, receiver: string, repeat_interval?: string}
# --record shape: {from: string, metric: string, target_datasource_uid?: string}
@deprecated
export def "provisioning-alert-rules RoutePutAlertRule" [
  UID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --annotations: record # e.g. {runbook_url: https://supercoolrunbook.com/page/13}
  condition: string # e.g. A
  data: list # e.g. [{datasourceUid: __expr__, model: {conditions: [{evaluator: {params: [0, 0], type: gt}, operator: {type: and}, query: {params: []}, reducer: {params: [], type: avg}, type: query}], datasource: {type: __expr__, uid: __expr__}, expression: 1 == 1, hide: false, intervalMs: 1000, maxDataPoints: 43200, refId: A, type: math}, queryType: , refId: A, relativeTimeRange: {from: 0, to: 0}}] — item shape: {datasourceUid?: string, model?: record, queryType?: string, refId?: string, relativeTimeRange?: record}
  execErrState: string@execErrState-completer
  folderUID: string # e.g. project_x
  --body-for: string # format: duration
  --id: int # format: int64
  --isPaused: string@bool-completer # e.g. false
  --keep-firing-for: string # format: duration
  --labels: record # e.g. {team: sre-team-1}
  --missingSeriesEvalsToResolve: int # format: int64, e.g. 2
  noDataState: string@noDataState-completer
  --notification-settings: record # shape: {active_time_intervals?: list, group_by?: list, group_interval?: string, group_wait?: string, mute_time_intervals?: list, receiver: string, repeat_interval?: string}
  orgID: int # format: int64
  --provenance: string
  --record: record # shape: {from: string, metric: string, target_datasource_uid?: string}
  ruleGroup: string # e.g. eval_group_1
  title: string # e.g. Always firing
  --uid: string
]: any -> record<annotations: record, condition: string, data: table<datasourceUid: string, model: record, queryType: string, refId: string, relativeTimeRange: record>, execErrState: string, folderUID: string, for: string, id: int, isPaused: bool, keep_firing_for: string, labels: record, missingSeriesEvalsToResolve: int, noDataState: string, notification_settings: record<active_time_intervals: list<string>, group_by: list<string>, group_interval: string, group_wait: string, mute_time_intervals: list<string>, receiver: string, repeat_interval: string>, orgID: int, provenance: string, record: record<from: string, metric: string, target_datasource_uid: string>, ruleGroup: string, title: string, uid: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/alert-rules/($UID)")
  let body = {annotations: $annotations, condition: $condition, data: $data, execErrState: $execErrState, folderUID: $folderUID, for: $body_for, id: $id, isPaused: $isPaused, keep_firing_for: $keep_firing_for, labels: $labels, missingSeriesEvalsToResolve: $missingSeriesEvalsToResolve, noDataState: $noDataState, notification_settings: $notification_settings, orgID: $orgID, provenance: $provenance, record: $record, ruleGroup: $ruleGroup, title: $title, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a specific alert rule by UID.
#
# DELETE /v1/provisioning/alert-rules/{UID}
# DEPRECATED
# operationId: RouteDeleteAlertRule
@deprecated
export def "provisioning-alert-rules RouteDeleteAlertRule" [
  UID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/alert-rules/($UID)")
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export an alert rule in provisioning file format.
#
# GET /v1/provisioning/alert-rules/{UID}/export
# operationId: RouteGetAlertRuleExport
export def "provisioning-alert-rules-export RouteGetAlertRuleExport" [
  UID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --download: string@bool-completer # Whether to initiate a download of the file or not. (default: false)
  --format: string@format-completer # Format of the downloaded file. Supported yaml, json or hcl. Accept header can also be used, but the query parameter will take precedence. (default: yaml)
]: nothing -> record<apiVersion: int, contactPoints: table<name: string, orgId: int, receivers: list>, groups: table<folder: string, interval: int, name: string, orgId: int, rules: list>, muteTimes: table<name: string, orgId: int, time_intervals: list>, policies: table<active_time_intervals: list, continue: bool, group_by: list, group_interval: string, group_wait: string, match: record, match_re: record, matchers: list, mute_time_intervals: list, object_matchers: list, orgId: int, receiver: string, repeat_interval: string, routes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/provisioning/alert-rules/($UID)/export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the contact points.
#
# GET /v1/provisioning/contact-points
# DEPRECATED
# operationId: RouteGetContactpoints
@deprecated
export def "provisioning-contact-points RouteGetContactpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Filter by name
]: nothing -> table<disableResolveMessage: bool, name: string, provenance: string, settings: record, type: string, uid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/provisioning/contact-points" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a contact point.
#
# POST /v1/provisioning/contact-points
# DEPRECATED
# operationId: RoutePostContactpoints
@deprecated
export def "provisioning-contact-points RoutePostContactpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --disableResolveMessage: string@bool-completer # e.g. false
  --name: string # Name is used as grouping key in the UI. Contact points with the same name will be grouped in the UI. (e.g. webhook_1)
  settings: record
  type: string@type-completer-2 # e.g. webhook
  --uid: string # UID is the unique identifier of the contact point. The UID can be set by the user. (e.g. my_external_reference)
]: any -> record<disableResolveMessage: bool, name: string, provenance: string, settings: record, type: string, uid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/contact-points")
  let body = {disableResolveMessage: $disableResolveMessage, name: $name, settings: $settings, type: $type, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export all contact points in provisioning file format.
#
# GET /v1/provisioning/contact-points/export
# operationId: RouteGetContactpointsExport
export def "provisioning-contact-points-export RouteGetContactpointsExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --download: string@bool-completer # Whether to initiate a download of the file or not. (default: false)
  --format: string@format-completer # Format of the downloaded file. Supported yaml, json or hcl. Accept header can also be used, but the query parameter will take precedence. (default: yaml)
  --decrypt: string@bool-completer # Whether any contained secure settings should be decrypted or left redacted. Redacted settings will contain RedactedValue instead. Currently, only org admin can view decrypted secure settings. (default: false)
  --name: string # Filter by name
]: nothing -> record<apiVersion: int, contactPoints: table<name: string, orgId: int, receivers: list>, groups: table<folder: string, interval: int, name: string, orgId: int, rules: list>, muteTimes: table<name: string, orgId: int, time_intervals: list>, policies: table<active_time_intervals: list, continue: bool, group_by: list, group_interval: string, group_wait: string, match: record, match_re: record, matchers: list, mute_time_intervals: list, object_matchers: list, orgId: int, receiver: string, repeat_interval: string, routes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "decrypt" $decrypt "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/provisioning/contact-points/export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact point.
#
# PUT /v1/provisioning/contact-points/{UID}
# DEPRECATED
# operationId: RoutePutContactpoint
@deprecated
export def "provisioning-contact-points RoutePutContactpoint" [
  UID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --disableResolveMessage: string@bool-completer # e.g. false
  --name: string # Name is used as grouping key in the UI. Contact points with the same name will be grouped in the UI. (e.g. webhook_1)
  settings: record
  type: string@type-completer-2 # e.g. webhook
  --uid: string # UID is the unique identifier of the contact point. The UID can be set by the user. (e.g. my_external_reference)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/contact-points/($UID)")
  let body = {disableResolveMessage: $disableResolveMessage, name: $name, settings: $settings, type: $type, uid: $uid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact point.
#
# DELETE /v1/provisioning/contact-points/{UID}
# DEPRECATED
# operationId: RouteDeleteContactpoints
@deprecated
export def "provisioning-contact-points RouteDeleteContactpoints" [
  UID: string
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
  let full_url = (build-url $base $"/v1/provisioning/contact-points/($UID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a rule group.
#
# GET /v1/provisioning/folder/{FolderUID}/rule-groups/{Group}
# DEPRECATED
# operationId: RouteGetAlertRuleGroup
@deprecated
export def "provisioning-folder-rule-groups RouteGetAlertRuleGroup" [
  FolderUID: string
  Group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<folderUid: string, interval: int, rules: table<annotations: record, condition: string, data: list, execErrState: string, folderUID: string, for: string, id: int, isPaused: bool, keep_firing_for: string, labels: record, missingSeriesEvalsToResolve: int, noDataState: string, notification_settings: record, orgID: int, provenance: string, record: record, ruleGroup: string, title: string, uid: string, updated: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/folder/($FolderUID)/rule-groups/($Group)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update alert rule group.
#
# PUT /v1/provisioning/folder/{FolderUID}/rule-groups/{Group}
# DEPRECATED
# operationId: RoutePutAlertRuleGroup
# --rules item shape: {annotations?: record, condition: string, data: list, execErrState: "OK"|"Alerting"|"Error", folderUID: string, for: string, id?: int, isPaused?: bool, keep_firing_for?: string, labels?: record, missingSeriesEvalsToResolve?: int, noDataState: "Alerting"|"NoData"|"OK", notification_settings?: record, orgID: int, provenance?: string, record?: record, ruleGroup: string, title: string, uid?: string}
@deprecated
export def "provisioning-folder-rule-groups RoutePutAlertRuleGroup" [
  FolderUID: string
  Group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --folderUid: string
  --interval: int # format: int64
  --rules: list # item shape: {annotations?: record, condition: string, data: list, execErrState: "OK"|"Alerting"|"Error", folderUID: string, for: string, id?: int, isPaused?: bool, keep_firing_for?: string, labels?: record, missingSeriesEvalsToResolve?: int, noDataState: "Alerting"|"NoData"|"OK", notification_settings?: record, orgID: int, provenance?: string, record?: record, ruleGroup: string, title: string, uid?: string}
  --title: string
]: any -> record<folderUid: string, interval: int, rules: table<annotations: record, condition: string, data: list, execErrState: string, folderUID: string, for: string, id: int, isPaused: bool, keep_firing_for: string, labels: record, missingSeriesEvalsToResolve: int, noDataState: string, notification_settings: record, orgID: int, provenance: string, record: record, ruleGroup: string, title: string, uid: string, updated: string>, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/folder/($FolderUID)/rule-groups/($Group)")
  let body = {folderUid: $folderUid, interval: $interval, rules: $rules, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete rule group
#
# DELETE /v1/provisioning/folder/{FolderUID}/rule-groups/{Group}
# DEPRECATED
# operationId: RouteDeleteAlertRuleGroup
@deprecated
export def "provisioning-folder-rule-groups RouteDeleteAlertRuleGroup" [
  FolderUID: string
  Group: string
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
  let full_url = (build-url $base $"/v1/provisioning/folder/($FolderUID)/rule-groups/($Group)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export an alert rule group in provisioning file format.
#
# GET /v1/provisioning/folder/{FolderUID}/rule-groups/{Group}/export
# operationId: RouteGetAlertRuleGroupExport
export def "provisioning-folder-rule-groups-export RouteGetAlertRuleGroupExport" [
  FolderUID: string
  Group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --download: string@bool-completer # Whether to initiate a download of the file or not. (default: false)
  --format: string@format-completer # Format of the downloaded file. Supported yaml, json or hcl. Accept header can also be used, but the query parameter will take precedence. (default: yaml)
]: nothing -> record<apiVersion: int, contactPoints: table<name: string, orgId: int, receivers: list>, groups: table<folder: string, interval: int, name: string, orgId: int, rules: list>, muteTimes: table<name: string, orgId: int, time_intervals: list>, policies: table<active_time_intervals: list, continue: bool, group_by: list, group_interval: string, group_wait: string, match: record, match_re: record, matchers: list, mute_time_intervals: list, object_matchers: list, orgId: int, receiver: string, repeat_interval: string, routes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/provisioning/folder/($FolderUID)/rule-groups/($Group)/export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the mute timings.
#
# GET /v1/provisioning/mute-timings
# DEPRECATED
# operationId: RouteGetMuteTimings
@deprecated
export def "provisioning-mute-timings RouteGetMuteTimings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, time_intervals: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/mute-timings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new mute timing.
#
# POST /v1/provisioning/mute-timings
# DEPRECATED
# operationId: RoutePostMuteTiming
# --time_intervals item shape: {name?: string, time_intervals?: list}
@deprecated
export def "provisioning-mute-timings RoutePostMuteTiming" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --name: string
  --time-intervals: list # item shape: {name?: string, time_intervals?: list}
]: any -> record<name: string, time_intervals: table<name: string, time_intervals: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/mute-timings")
  let body = {name: $name, time_intervals: $time_intervals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export all mute timings in provisioning format.
#
# GET /v1/provisioning/mute-timings/export
# operationId: RouteExportMuteTimings
export def "provisioning-mute-timings-export RouteExportMuteTimings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --download: string@bool-completer # Whether to initiate a download of the file or not. (default: false)
  --format: string@format-completer # Format of the downloaded file. Supported yaml, json or hcl. Accept header can also be used, but the query parameter will take precedence. (default: yaml)
]: nothing -> record<apiVersion: int, contactPoints: table<name: string, orgId: int, receivers: list>, groups: table<folder: string, interval: int, name: string, orgId: int, rules: list>, muteTimes: table<name: string, orgId: int, time_intervals: list>, policies: table<active_time_intervals: list, continue: bool, group_by: list, group_interval: string, group_wait: string, match: record, match_re: record, matchers: list, mute_time_intervals: list, object_matchers: list, orgId: int, receiver: string, repeat_interval: string, routes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/provisioning/mute-timings/export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a mute timing.
#
# GET /v1/provisioning/mute-timings/{name}
# DEPRECATED
# operationId: RouteGetMuteTiming
@deprecated
export def "provisioning-mute-timings RouteGetMuteTiming" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, time_intervals: table<name: string, time_intervals: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/mute-timings/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Replace an existing mute timing.
#
# PUT /v1/provisioning/mute-timings/{name}
# DEPRECATED
# operationId: RoutePutMuteTiming
# --time_intervals item shape: {name?: string, time_intervals?: list}
@deprecated
export def "provisioning-mute-timings RoutePutMuteTiming" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --body-name: string
  --time-intervals: list # item shape: {name?: string, time_intervals?: list}
]: any -> record<name: string, time_intervals: table<name: string, time_intervals: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/mute-timings/($name)")
  let body = {name: $body_name, time_intervals: $time_intervals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a mute timing.
#
# DELETE /v1/provisioning/mute-timings/{name}
# DEPRECATED
# operationId: RouteDeleteMuteTiming
@deprecated
export def "provisioning-mute-timings RouteDeleteMuteTiming" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # Version of mute timing to use for optimistic concurrency. Leave empty to disable validation
  --X-Disable-Provenance: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/provisioning/mute-timings/($name)" $qp)
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a mute timing in provisioning format.
#
# GET /v1/provisioning/mute-timings/{name}/export
# operationId: RouteExportMuteTiming
export def "provisioning-mute-timings-export RouteExportMuteTiming" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --download: string@bool-completer # Whether to initiate a download of the file or not. (default: false)
  --format: string@format-completer # Format of the downloaded file. Supported yaml, json or hcl. Accept header can also be used, but the query parameter will take precedence. (default: yaml)
]: nothing -> record<apiVersion: int, contactPoints: table<name: string, orgId: int, receivers: list>, groups: table<folder: string, interval: int, name: string, orgId: int, rules: list>, muteTimes: table<name: string, orgId: int, time_intervals: list>, policies: table<active_time_intervals: list, continue: bool, group_by: list, group_interval: string, group_wait: string, match: record, match_re: record, matchers: list, mute_time_intervals: list, object_matchers: list, orgId: int, receiver: string, repeat_interval: string, routes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/provisioning/mute-timings/($name)/export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the notification policy tree.
#
# GET /v1/provisioning/policies
# DEPRECATED
# operationId: RouteGetPolicyTree
@deprecated
export def "provisioning-policies RouteGetPolicyTree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active_time_intervals: list<string>, continue: bool, group_by: list<string>, group_interval: string, group_wait: string, match: record, match_re: record, matchers: table<Name: string, Type: int, Value: string>, mute_time_intervals: list<string>, object_matchers: list<list<string>>, provenance: string, receiver: string, repeat_interval: string, routes: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sets the notification policy tree.
#
# PUT /v1/provisioning/policies
# DEPRECATED
# operationId: RoutePutPolicyTree
# --matchers item shape: {Name?: string, Type?: int, Value?: string}
# --routes item shape: {active_time_intervals?: list, continue?: bool, group_by?: list, group_interval?: string, group_wait?: string, match?: record, match_re?: record, matchers?: list, mute_time_intervals?: list, object_matchers?: list, provenance?: string, receiver?: string, repeat_interval?: string, routes?: list}
@deprecated
export def "provisioning-policies RoutePutPolicyTree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --active-time-intervals: list
  --body-continue: string@bool-completer
  --group-by: list
  --group-interval: string
  --group-wait: string
  --body-match: record # Deprecated. Remove before v1.0 release.
  --match-re: record
  --matchers: list # Matchers is a slice of Matchers that is sortable, implements Stringer, and provides a Matches method to match a LabelSet against all Matchers in the slice. Note that some users of Matchers might require it to be sorted. — item shape: {Name?: string, Type?: int, Value?: string}
  --mute-time-intervals: list
  --object-matchers: list
  --provenance: string
  --receiver: string
  --repeat-interval: string
  --routes: list # item shape: {active_time_intervals?: list, continue?: bool, group_by?: list, group_interval?: string, group_wait?: string, match?: record, match_re?: record, matchers?: list, mute_time_intervals?: list, object_matchers?: list, provenance?: string, receiver?: string, repeat_interval?: string, routes?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/policies")
  let body = {active_time_intervals: $active_time_intervals, continue: $body_continue, group_by: $group_by, group_interval: $group_interval, group_wait: $group_wait, match: $body_match, match_re: $match_re, matchers: $matchers, mute_time_intervals: $mute_time_intervals, object_matchers: $object_matchers, provenance: $provenance, receiver: $receiver, repeat_interval: $repeat_interval, routes: $routes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clears the notification policy tree.
#
# DELETE /v1/provisioning/policies
# DEPRECATED
# operationId: RouteResetPolicyTree
@deprecated
export def "provisioning-policies RouteResetPolicyTree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export the notification policy tree in provisioning file format.
#
# GET /v1/provisioning/policies/export
# operationId: RouteGetPolicyTreeExport
export def "provisioning-policies-export RouteGetPolicyTreeExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<apiVersion: int, contactPoints: table<name: string, orgId: int, receivers: list>, groups: table<folder: string, interval: int, name: string, orgId: int, rules: list>, muteTimes: table<name: string, orgId: int, time_intervals: list>, policies: table<active_time_intervals: list, continue: bool, group_by: list, group_interval: string, group_wait: string, match: record, match_re: record, matchers: list, mute_time_intervals: list, object_matchers: list, orgId: int, receiver: string, repeat_interval: string, routes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/policies/export")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all notification template groups.
#
# GET /v1/provisioning/templates
# DEPRECATED
# operationId: RouteGetTemplates
@deprecated
export def "provisioning-templates RouteGetTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, provenance: string, template: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/provisioning/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a notification template group.
#
# GET /v1/provisioning/templates/{name}
# DEPRECATED
# operationId: RouteGetTemplate
@deprecated
export def "provisioning-templates RouteGetTemplate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, provenance: string, template: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/templates/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an existing notification template group.
#
# PUT /v1/provisioning/templates/{name}
# DEPRECATED
# operationId: RoutePutTemplate
@deprecated
export def "provisioning-templates RoutePutTemplate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Disable-Provenance: string
  --template: string
  --version: string
]: any -> record<name: string, provenance: string, template: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/provisioning/templates/($name)")
  let body = {template: $template, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Disable-Provenance": $X_Disable_Provenance} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a notification template group.
#
# DELETE /v1/provisioning/templates/{name}
# DEPRECATED
# operationId: RouteDeleteTemplate
@deprecated
export def "provisioning-templates RouteDeleteTemplate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version: string # Version of template to use for optimistic concurrency. Leave empty to disable validation
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/provisioning/templates/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all SSO Settings entries
#
# GET /v1/sso-settings
# operationId: listAllProvidersSettings
export def "sso-settings listAllProvidersSettings" [
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
  let full_url = (build-url $base "/v1/sso-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an SSO Settings entry by Key
#
# GET /v1/sso-settings/{key}
# operationId: getProviderSettings
export def "sso-settings get" [
  key: string
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
  let full_url = (build-url $base $"/v1/sso-settings/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SSO Settings
#
# PUT /v1/sso-settings/{key}
# operationId: updateProviderSettings
export def "sso-settings updateProviderSettings" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string
  --provider: string
  --settings: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sso-settings/($key)")
  let body = {id: $id, provider: $provider, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove SSO Settings
#
# DELETE /v1/sso-settings/{key}
# operationId: removeProviderSettings
export def "sso-settings removeProviderSettings" [
  key: string
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
  let full_url = (build-url $base $"/v1/sso-settings/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch SSO Settings
#
# PATCH /v1/sso-settings/{key}
# operationId: patchProviderSettings
export def "sso-settings patch" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --settings: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sso-settings/($key)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
