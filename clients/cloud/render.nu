# Auto-generated client for Render Public API v1.0.0
# Source: https://api-docs.render.com/openapi/render-public-api-1.json
# Auth: --token flag or $env.RENDER_PUBLIC_API_TOKEN

const BASE_URL = "https://api.render.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RENDER_PUBLIC_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.render.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def role-completer [] { ["ADMIN" "DEVELOPER" "WORKSPACE_BILLING" "WORKSPACE_CONTRIBUTOR" "WORKSPACE_VIEWER"] }
def region-completer [] { ["frankfurt" "ohio" "oregon" "singapore" "virginia"] }
def notificationsToSend-completer [] { ["all" "failure" "none"] }
def registry-completer [] { ["AWS_ECR" "DOCKER" "GITHUB" "GITLAB" "GOOGLE_ARTIFACT"] }
def type-completer [] { ["background_worker" "cron_job" "private_service" "static_site" "web_service"] }
def autoDeploy-completer [] { ["no" "yes"] }
def clearCache-completer [] { ["clear" "do_not_clear"] }
def deployMode-completer [] { ["build_and_deploy" "deploy_only"] }
def type-completer-1 [] { ["redirect" "rewrite"] }
def domainType-completer [] { ["apex" "subdomain"] }
def verificationStatus-completer [] { ["unverified" "verified"] }
def plan-completer [] { ["custom" "free" "pro" "pro_legacy" "pro_max" "pro_plus" "pro_plus_legacy" "pro_ultra" "standard" "standard_legacy" "standard_plus" "standard_plus_legacy" "starter" "starter_legacy" "starter_plus"] }
def direction-completer [] { ["backward" "forward"] }
def label-completer [] { ["host" "instance" "level" "method" "statusCode" "type"] }
def preview-completer [] { ["drop" "send"] }
def provider-completer [] { ["BETTER_STACK" "CUSTOM" "DATADOG" "GRAFANA" "GROUNDCOVER" "HONEYCOMB" "LOGFIRE" "NEW_RELIC" "SIGNOZ"] }
def aggregationMethod-completer [] { ["AVG" "MAX" "MIN"] }
def aggregateBy-completer [] { ["host" "statusCode"] }
def state-completer [] { ["failed" "succeeded"] }
def aggregateBy-completer-1 [] { ["state"] }
def plan-completer-1 [] { ["custom" "free" "pro" "pro_plus" "standard" "starter"] }
def maxmemoryPolicy-completer [] { ["allkeys_lfu" "allkeys_lru" "allkeys_random" "noeviction" "volatile_lfu" "volatile_lru" "volatile_random" "volatile_ttl"] }
def persistenceMode-completer [] { ["journal_snapshot" "off" "snapshot"] }
def version-completer [] { ["11" "12" "13" "14" "15" "16" "17" "18"] }
def protectedStatus-completer [] { ["protected" "unprotected"] }
def Accept-completer [] { ["text/event-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "blueprints list-blueprints" } } | get name | first)
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

# List Blueprints
#
# GET /blueprints
# operationId: list-blueprints
export def "blueprints list-blueprints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: list # The ID of the workspaces to return resources for
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<blueprint: record<id: any, name: string, status: string, autoSync: bool, repo: string, branch: string, path: string, lastSync: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blueprints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Blueprint
#
# POST /blueprints/validate
# operationId: validate-blueprint
export def "blueprints-validate validate-blueprint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ownerId: string # The ID of the workspace to validate against. Obtain your workspace ID from its Settings page in the Render Dashboard. (e.g. tea-cjnxpkdhshc73d12t9i0)
  file: string # The render.yaml file to validate, as a binary file. (format: binary)
]: any -> record<valid: bool, errors: table<path: string, error: string, line: int, column: int>, plan: record<services: list<string>, databases: list<string>, keyValue: list<string>, envGroups: list<string>, totalActions: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blueprints/validate")
  let body = {ownerId: $ownerId, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Update workspace member role
#
# PATCH /owners/{ownerId}/members/{userId}
# operationId: update-workspace-member
export def "owners-members update-workspace-member" [
  ownerId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: string@role-completer # The member's workspace role. Values are always returned in uppercase. (e.g. DEVELOPER)
]: any -> record<userId: string, name: string, email: string, status: string, role: string, mfaEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/owners/($ownerId)/members/($userId)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove workspace member
#
# DELETE /owners/{ownerId}/members/{userId}
# operationId: remove-workspace-member
export def "owners-members remove-workspace-member" [
  ownerId: string
  userId: string
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
  let full_url = (build-url $base $"/owners/($ownerId)/members/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Blueprint
#
# GET /blueprints/{blueprintId}
# operationId: retrieve-blueprint
export def "blueprints retrieve-blueprint" [
  blueprintId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: any, name: string, status: any, autoSync: any, repo: string, branch: string, path: any, lastSync: string, resources: table<id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blueprints/($blueprintId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Blueprint
#
# PATCH /blueprints/{blueprintId}
# operationId: update-blueprint
export def "blueprints update-blueprint" [
  blueprintId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --autoSync: any
  --path: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/blueprints/($blueprintId)")
  let body = {name: $name, autoSync: $autoSync, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disconnect Blueprint
#
# DELETE /blueprints/{blueprintId}
# operationId: disconnect-blueprint
export def "blueprints disconnect-blueprint" [
  blueprintId: string
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
  let full_url = (build-url $base $"/blueprints/($blueprintId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Blueprint syncs
#
# GET /blueprints/{blueprintId}/syncs
# operationId: list-blueprint-syncs
export def "blueprints-syncs list-blueprint-syncs" [
  blueprintId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<sync: record<id: string, commit: record, startedAt: string, completedAt: string, state: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/blueprints/($blueprintId)/syncs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List dedicated IPs
#
# GET /dedicated-ips
# operationId: list-dedicated-ips
export def "dedicated-ips list-dedicated-ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: string # The ID of the workspace to list dedicated IP sets for.
]: nothing -> table<id: string, name: string, description: string, ownerId: string, region: string, environmentIds: list<string>, ips: list<string>, status: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dedicated-ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create dedicated IP set
#
# POST /dedicated-ips
# operationId: create-dedicated-ip
export def "dedicated-ips create-dedicated-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name for the dedicated IP set.
  --description: string # Free-form description for the dedicated IP set.
  ownerId: string # The ID of the workspace that will own this dedicated IP set.
  region: string@region-completer # Defaults to "oregon" (default: oregon)
  --environmentIds: list # Environments to scope the dedicated IP set to. If omitted or empty, it applies to all services in the workspace within its region.
]: any -> record<id: string, name: string, description: string, ownerId: string, region: string, environmentIds: list<string>, ips: list<string>, status: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dedicated-ips")
  let body = {name: $name, description: $description, ownerId: $ownerId, region: $region, environmentIds: $environmentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve dedicated IP set
#
# GET /dedicated-ips/{dedicatedIpId}
# operationId: retrieve-dedicated-ip
export def "dedicated-ips retrieve-dedicated-ip" [
  dedicatedIpId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, description: string, ownerId: string, region: string, environmentIds: list<string>, ips: list<string>, status: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dedicated-ips/($dedicatedIpId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update dedicated IP set
#
# PATCH /dedicated-ips/{dedicatedIpId}
# operationId: update-dedicated-ip
export def "dedicated-ips update-dedicated-ip" [
  dedicatedIpId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string
  --environmentIds: list
]: any -> record<id: string, name: string, description: string, ownerId: string, region: string, environmentIds: list<string>, ips: list<string>, status: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dedicated-ips/($dedicatedIpId)")
  let body = {name: $name, description: $description, environmentIds: $environmentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete dedicated IP set
#
# DELETE /dedicated-ips/{dedicatedIpId}
# operationId: delete-dedicated-ip
export def "dedicated-ips delete-dedicated-ip" [
  dedicatedIpId: string
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
  let full_url = (build-url $base $"/dedicated-ips/($dedicatedIpId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List disks
#
# GET /disks
# operationId: list-disks
export def "disks list-disks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: list # The ID of the workspaces to return resources for
  --diskId: list # Filter by disk IDs
  --name: list # Filter by name
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --serviceId: list # Filter for resources by service ID
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<disk: record<id: any, name: string, sizeGB: int, mountPath: string, serviceId: string, createdAt: string, updatedAt: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "csv") (serialize-qp "diskId" $diskId "multi") (serialize-qp "name" $name "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "serviceId" $serviceId "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/disks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add disk
#
# POST /disks
# operationId: add-disk
export def "disks add-disk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  sizeGB: int
  mountPath: string
  serviceId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/disks")
  let body = {name: $name, sizeGB: $sizeGB, mountPath: $mountPath, serviceId: $serviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve disk
#
# GET /disks/{diskId}
# operationId: retrieve-disk
export def "disks retrieve-disk" [
  diskId: string
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
  let full_url = (build-url $base $"/disks/($diskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update disk
#
# PATCH /disks/{diskId}
# operationId: update-disk
export def "disks update-disk" [
  diskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --sizeGB: int
  --mountPath: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/disks/($diskId)")
  let body = {name: $name, sizeGB: $sizeGB, mountPath: $mountPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete disk
#
# DELETE /disks/{diskId}
# operationId: delete-disk
export def "disks delete-disk" [
  diskId: string
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
  let full_url = (build-url $base $"/disks/($diskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List snapshots
#
# GET /disks/{diskId}/snapshots
# operationId: list-snapshots
export def "disks-snapshots list-snapshots" [
  diskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<createdAt: string, snapshotKey: string, instanceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/disks/($diskId)/snapshots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore snapshot
#
# POST /disks/{diskId}/snapshots/restore
# operationId: restore-snapshot
export def "disks-snapshots-restore restore-snapshot" [
  diskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  snapshotKey: string
  --instanceId: string # When a service with a disk is scaled, the instanceId is used to identify the instance that the disk is attached to. Each instance's disks get their own snapshots, and can be restored separately.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/disks/($diskId)/snapshots/restore")
  let body = {snapshotKey: $snapshotKey, instanceId: $instanceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the authenticated user
#
# GET /users
# operationId: get-user
export def "users get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspaces
#
# GET /owners
# operationId: list-owners
export def "owners list-owners" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Only return workspaces with one of the provided names. Only exact matches are returned.
  --email: list # Only return workspaces owned by one of the provided email addresses.
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<owner: record<id: string, name: string, email: string, ipAllowList: list, twoFactorAuthEnabled: bool, type: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "multi") (serialize-qp "email" $email "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/owners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve workspace
#
# GET /owners/{ownerId}
# operationId: retrieve-owner
export def "owners retrieve-owner" [
  ownerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, email: string, ipAllowList: table<cidrBlock: string, description: string>, twoFactorAuthEnabled: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/owners/($ownerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspace members
#
# GET /owners/{ownerId}/members
# operationId: retrieve-owner-members
export def "owners-members retrieve-owner-members" [
  ownerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<userId: string, name: string, email: string, status: string, role: string, mfaEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/owners/($ownerId)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspace audit logs
#
# GET /owners/{ownerId}/audit-logs
# operationId: list-owner-audit-logs
export def "owners-audit-logs list-owner-audit-logs" [
  ownerId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Start time for filtering audit logs (ISO 8601 format) (format: date-time, e.g. 2023-01-01T00:00:00Z)
  --endTime: string # End time for filtering audit logs (ISO 8601 format) (format: date-time, e.g. 2023-12-31T23:59:59Z)
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of audit log items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<cursor: string, auditLog: record<id: string, timestamp: string, event: string, status: string, actor: record, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/owners/($ownerId)/audit-logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization audit logs
#
# GET /organizations/{orgId}/audit-logs
# operationId: list-organization-audit-logs
export def "organizations-audit-logs list-organization-audit-logs" [
  orgId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Start time for filtering audit logs (ISO 8601 format) (format: date-time, e.g. 2023-01-01T00:00:00Z)
  --endTime: string # End time for filtering audit logs (ISO 8601 format) (format: date-time, e.g. 2023-12-31T23:59:59Z)
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of audit log items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<cursor: string, auditLog: record<id: string, timestamp: string, event: string, status: string, actor: record, metadata: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($orgId)/audit-logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve notification settings
#
# GET /notification-settings/owners/{ownerId}
# operationId: retrieve-owner-notification-settings
export def "notification-settings-owners retrieve-owner-notification-settings" [
  ownerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ownerId: string, slackEnabled: bool, emailEnabled: bool, previewNotificationsEnabled: bool, notificationsToSend: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notification-settings/owners/($ownerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update notification settings
#
# PATCH /notification-settings/owners/{ownerId}
# operationId: patch-owner-notification-settings
export def "notification-settings-owners patch-owner-notification-settings" [
  ownerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emailEnabled: oneof<nothing, bool>
  --previewNotificationsEnabled: oneof<nothing, bool>
  --notificationsToSend: string@notificationsToSend-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notification-settings/owners/($ownerId)")
  let body = {emailEnabled: $emailEnabled, previewNotificationsEnabled: $previewNotificationsEnabled, notificationsToSend: $notificationsToSend} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List notification overrides
#
# GET /notification-settings/overrides
# operationId: list-notification-overrides
export def "notification-settings-overrides list-notification-overrides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: list # The ID of the workspaces to return resources for
  --serviceId: list # Filter for resources by service ID
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<override: record<serviceId: string, previewNotificationsEnabled: string, notificationsToSend: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "csv") (serialize-qp "serviceId" $serviceId "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notification-settings/overrides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve notification override
#
# GET /notification-settings/overrides/services/{serviceId}
# operationId: retrieve-service-notification-overrides
export def "notification-settings-overrides-services retrieve-service-notification-overrides" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<serviceId: string, previewNotificationsEnabled: any, notificationsToSend: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notification-settings/overrides/services/($serviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update notification override
#
# PATCH /notification-settings/overrides/services/{serviceId}
# operationId: patch-service-notification-overrides
export def "notification-settings-overrides-services patch-service-notification-overrides" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --previewNotificationsEnabled: any
  --notificationsToSend: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notification-settings/overrides/services/($serviceId)")
  let body = {previewNotificationsEnabled: $previewNotificationsEnabled, notificationsToSend: $notificationsToSend} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List registry credentials
#
# GET /registrycredentials
# operationId: list-registry-credentials
export def "registrycredentials list-registry-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter for the name of a credential
  --username: list # Filter for the username of a credential
  --type: list # Filter for the registry type for the credential
  --createdBefore: string # Filter for services created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for services created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for services updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for services updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<id: string, name: string, registry: string, username: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "username" $username "csv") (serialize-qp "type" $type "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/registrycredentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create registry credential
#
# POST /registrycredentials
# operationId: create-registry-credential
export def "registrycredentials create-registry-credential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  registry: string@registry-completer # The registry to use this credential with
  name: string
  username: string
  authToken: string
  ownerId: string
]: any -> record<id: string, name: string, registry: string, username: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registrycredentials")
  let body = {registry: $registry, name: $name, username: $username, authToken: $authToken, ownerId: $ownerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve registry credential
#
# GET /registrycredentials/{registryCredentialId}
# operationId: retrieve-registry-credential
export def "registrycredentials retrieve-registry-credential" [
  registryCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, registry: string, username: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registrycredentials/($registryCredentialId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update registry credential
#
# PATCH /registrycredentials/{registryCredentialId}
# operationId: update-registry-credential
export def "registrycredentials update-registry-credential" [
  registryCredentialId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  registry: string@registry-completer # The registry to use this credential with
  name: string
  username: string
  authToken: string
]: any -> record<id: string, name: string, registry: string, username: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/registrycredentials/($registryCredentialId)")
  let body = {registry: $registry, name: $name, username: $username, authToken: $authToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete registry credential
#
# DELETE /registrycredentials/{registryCredentialId}
# operationId: delete-registry-credential
export def "registrycredentials delete-registry-credential" [
  registryCredentialId: string
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
  let full_url = (build-url $base $"/registrycredentials/($registryCredentialId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List services
#
# GET /services
# operationId: list-services
@deprecated --flag env
export def "services list-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --type: list # Filter for types of services
  --environmentId: list # Filter for resources that belong to an environment
  --env: list # Filter for environments (runtimes) of services (deprecated; use `runtime` instead) (DEPRECATED)
  --region: list # Filter by resource region
  --suspended: list # Filter resources based on whether they're suspended or not suspended
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --includePreviews: oneof<nothing, bool> # Include previews in the response (default: true)
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<service: record<id: string, autoDeploy: string, branch: string, buildFilter: record, createdAt: string, dashboardUrl: string, environmentId: string, imagePath: string, name: string, notifyOnFail: string, ownerId: string, registryCredential: record, repo: string, rootDir: string, slug: string, suspended: string, suspenders: list, type: string, updatedAt: string, serviceDetails: any>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "type" $type "csv") (serialize-qp "environmentId" $environmentId "csv") (serialize-qp "env" $env "csv") (serialize-qp "region" $region "csv") (serialize-qp "suspended" $suspended "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "includePreviews" $includePreviews "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create service
#
# POST /services
# operationId: create-service
# --image shape: {ownerId: string, registryCredentialId?: string, imagePath: string}
# --buildFilter shape: {paths: list, ignoredPaths: list}
# --secretFiles item shape: {name: string, content: string}
export def "services create-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer
  name: string # The service's name. Must be unique within the workspace.
  ownerId: string # The ID of the workspace the service belongs to. Obtain your workspace's ID from its Settings page in the Render Dashboard.
  --repo: string # The service's repository URL. Do not specify a branch in this string (use the `branch` parameter instead). (e.g. https://github.com/render-examples/flask-hello-world)
  --autoDeploy: string@autoDeploy-completer # default: yes
  --branch: string # The repo branch to pull, build, and deploy. If omitted, uses the repository's default branch.
  --image: record # shape: {ownerId: string, registryCredentialId?: string, imagePath: string}
  --buildFilter: record # shape: {paths: list, ignoredPaths: list}
  --rootDir: string
  --envVars: list
  --secretFiles: list # item shape: {name: string, content: string}
  --environmentId: string # The ID of the environment the service belongs to, if any. Obtain an environment's ID from its Settings page in the Render Dashboard.
  --serviceDetails: any
]: any -> record<service: record<id: string, autoDeploy: string, branch: string, buildFilter: record<paths: list, ignoredPaths: list>, createdAt: string, dashboardUrl: string, environmentId: string, imagePath: string, name: string, notifyOnFail: string, ownerId: string, registryCredential: record<id: string, name: string>, repo: string, rootDir: string, slug: string, suspended: string, suspenders: list<string>, type: string, updatedAt: string, serviceDetails: any>, deployId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/services")
  let body = {type: $type, name: $name, ownerId: $ownerId, repo: $repo, autoDeploy: $autoDeploy, branch: $branch, image: $image, buildFilter: $buildFilter, rootDir: $rootDir, envVars: $envVars, secretFiles: $secretFiles, environmentId: $environmentId, serviceDetails: $serviceDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve service
#
# GET /services/{serviceId}
# operationId: retrieve-service
export def "services retrieve-service" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, autoDeploy: string, branch: string, buildFilter: record<paths: list<string>, ignoredPaths: list<string>>, createdAt: string, dashboardUrl: string, environmentId: string, imagePath: string, name: string, notifyOnFail: string, ownerId: string, registryCredential: record<id: string, name: string>, repo: string, rootDir: string, slug: string, suspended: string, suspenders: list<string>, type: string, updatedAt: string, serviceDetails: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update service
#
# PATCH /services/{serviceId}
# operationId: update-service
# --image shape: {ownerId: string, registryCredentialId?: string, imagePath: string}
# --buildFilter shape: {paths: list, ignoredPaths: list}
export def "services update-service" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoDeploy: string@autoDeploy-completer # default: yes
  --repo: string
  --branch: string
  --image: record # shape: {ownerId: string, registryCredentialId?: string, imagePath: string}
  --name: string
  --buildFilter: record # shape: {paths: list, ignoredPaths: list}
  --rootDir: string
  --serviceDetails: any
]: any -> record<id: string, autoDeploy: string, branch: string, buildFilter: record<paths: list<string>, ignoredPaths: list<string>>, createdAt: string, dashboardUrl: string, environmentId: string, imagePath: string, name: string, notifyOnFail: string, ownerId: string, registryCredential: record<id: string, name: string>, repo: string, rootDir: string, slug: string, suspended: string, suspenders: list<string>, type: string, updatedAt: string, serviceDetails: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)")
  let body = {autoDeploy: $autoDeploy, repo: $repo, branch: $branch, image: $image, name: $name, buildFilter: $buildFilter, rootDir: $rootDir, serviceDetails: $serviceDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete service
#
# DELETE /services/{serviceId}
# operationId: delete-service
export def "services delete-service" [
  serviceId: string
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
  let full_url = (build-url $base $"/services/($serviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purge Web Service Cache
#
# POST /services/{serviceId}/cache/purge
# operationId: purge-cache
export def "services-cache-purge purge-cache" [
  serviceId: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/cache/purge")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List deploys
#
# GET /services/{serviceId}/deploys
# operationId: list-deploys
export def "services-deploys list-deploys" [
  serviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Filter for deploys with the specified statuses
  --createdBefore: string # Filter for deploys created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for deploys created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for deploys updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for deploys updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --finishedBefore: string # Filter for deploys finished before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --finishedAfter: string # Filter for deploys finished after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<deploy: record<id: string, commit: record, image: record, status: string, trigger: string, startedAt: string, finishedAt: string, createdAt: string, updatedAt: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "finishedBefore" $finishedBefore "scalar") (serialize-qp "finishedAfter" $finishedAfter "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/deploys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger deploy
#
# POST /services/{serviceId}/deploys
# operationId: create-deploy
export def "services-deploys create-deploy" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clearCache: string@clearCache-completer # If `clear`, Render clears the service's build cache before deploying. This can be useful if you're experiencing issues with your build. (default: do_not_clear)
  --commitId: string # The SHA of a specific Git commit to deploy for a service. Defaults to the latest commit on the service's connected branch.  Note that deploying a specific commit with this endpoint does not disable autodeploys for the service.  You can toggle autodeploys for your service with the [Update service](https://api-docs.render.com/reference/update-service) endpoint or in the Render Dashboard.  Not supported for cron jobs.
  --imageUrl: string # The URL of the image to deploy for an image-backed service.  The host, repository, and image name all must match the currently configured image for the service.
  --deployMode: string@deployMode-completer # Controls deployment behavior when triggering a deploy.  - `deploy_only`: Deploy the last successful build without rebuilding (minimizes downtime) - `build_and_deploy`: Build new code and deploy it (default behavior when not specified)  **Note:** `deploy_only` cannot be combined with `commitId`, `imageUrl` or `clearCache` parameters, as those are build related fields.  (default: build_and_deploy)
]: any -> record<id: string, commit: record<id: string, message: string, createdAt: string>, image: record<ref: string, sha: string, registryCredential: string>, status: string, trigger: string, startedAt: string, finishedAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/deploys")
  let body = {clearCache: $clearCache, commitId: $commitId, imageUrl: $imageUrl, deployMode: $deployMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve deploy
#
# GET /services/{serviceId}/deploys/{deployId}
# operationId: retrieve-deploy
export def "services-deploys retrieve-deploy" [
  serviceId: string
  deployId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, commit: record<id: string, message: string, createdAt: string>, image: record<ref: string, sha: string, registryCredential: string>, status: string, trigger: string, startedAt: string, finishedAt: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/deploys/($deployId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel deploy
#
# POST /services/{serviceId}/deploys/{deployId}/cancel
# operationId: cancel-deploy
export def "services-deploys-cancel cancel-deploy" [
  serviceId: string
  deployId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, commit: record<id: string, message: string, createdAt: string>, image: record<ref: string, sha: string, registryCredential: string>, status: string, trigger: string, startedAt: string, finishedAt: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/deploys/($deployId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Roll back deploy
#
# POST /services/{serviceId}/rollback
# operationId: rollback-deploy
export def "services-rollback rollback-deploy" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  deployId: string # The ID of the deploy to roll back to
]: any -> record<id: string, commit: record<id: string, message: string, createdAt: string>, image: record<ref: string, sha: string, registryCredential: string>, status: string, trigger: string, startedAt: string, finishedAt: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/rollback")
  let body = {deployId: $deployId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List environment variables
#
# GET /services/{serviceId}/env-vars
# operationId: get-env-vars-for-service
export def "services-env-vars get-env-vars-for-service" [
  serviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<envVar: record<key: string, value: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/env-vars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update environment variables
#
# PUT /services/{serviceId}/env-vars
# operationId: update-env-vars-for-service
export def "services-env-vars update-env-vars-for-service" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<envVar: record<key: string, value: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/env-vars")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve environment variable
#
# GET /services/{serviceId}/env-vars/{envVarKey}
# operationId: retrieve-env-var
export def "services-env-vars retrieve-env-var" [
  serviceId: string
  envVarKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/env-vars/($envVarKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update environment variable
#
# PUT /services/{serviceId}/env-vars/{envVarKey}
# operationId: update-env-var
export def "services-env-vars update-env-var" [
  serviceId: string
  envVarKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: string
  --generateValue: oneof<nothing, bool>
]: any -> record<key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/env-vars/($envVarKey)")
  let body = {value: $value, generateValue: $generateValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete environment variable
#
# DELETE /services/{serviceId}/env-vars/{envVarKey}
# operationId: delete-env-var
export def "services-env-vars delete-env-var" [
  serviceId: string
  envVarKey: string
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
  let full_url = (build-url $base $"/services/($serviceId)/env-vars/($envVarKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List secret files
#
# GET /services/{serviceId}/secret-files
# operationId: list-secret-files-for-service
export def "services-secret-files list-secret-files-for-service" [
  serviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<secretFile: record<name: string, content: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/secret-files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update secret files
#
# PUT /services/{serviceId}/secret-files
# operationId: update-secret-files-for-service
export def "services-secret-files update-secret-files-for-service" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<secretFile: record<name: string, content: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/secret-files")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve secret file
#
# GET /services/{serviceId}/secret-files/{secretFileName}
# operationId: retrieve-secret-file
export def "services-secret-files retrieve-secret-file" [
  serviceId: string
  secretFileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/secret-files/($secretFileName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update secret file
#
# PUT /services/{serviceId}/secret-files/{secretFileName}
# operationId: add-or-update-secret-file
export def "services-secret-files add-or-update-secret-file" [
  serviceId: string
  secretFileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string
]: any -> record<name: string, content: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/secret-files/($secretFileName)")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete secret file
#
# DELETE /services/{serviceId}/secret-files/{secretFileName}
# operationId: delete-secret-file
export def "services-secret-files delete-secret-file" [
  serviceId: string
  secretFileName: string
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
  let full_url = (build-url $base $"/services/($serviceId)/secret-files/($secretFileName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List events
#
# GET /services/{serviceId}/events
# operationId: list-events
export def "services-events list-events" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # The type of event to filter to
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<event: record<id: any, timestamp: string, serviceId: string, type: any, details: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List header rules
#
# GET /services/{serviceId}/headers
# operationId: list-headers
export def "services-headers list-headers" [
  serviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: list # Filter for specific paths that headers apply to
  --name: list # Filter for header names
  --value: list # Filter for header values
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<header: record<id: string, path: string, name: string, value: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "csv") (serialize-qp "name" $name "csv") (serialize-qp "value" $value "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/headers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add header rule
#
# POST /services/{serviceId}/headers
# operationId: add-headers
export def "services-headers add-headers" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  path: string # The request path to add the header to. Wildcards will cause headers to be applied to all matching paths. (e.g. /static/*)
  name: string # Header name (e.g. Cache-Control)
  value: string # Header value (e.g. public, max-age=604800)
]: any -> record<headers: record<id: string, path: string, name: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/headers")
  let body = {path: $path, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace header rules
#
# PUT /services/{serviceId}/headers
# operationId: update-headers
export def "services-headers update-headers" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, path: string, name: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/headers")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete header rule
#
# DELETE /services/{serviceId}/headers/{headerId}
# operationId: delete-header
export def "services-headers delete-header" [
  serviceId: string
  headerId: string
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
  let full_url = (build-url $base $"/services/($serviceId)/headers/($headerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List redirect/rewrite rules
#
# GET /services/{serviceId}/routes
# operationId: list-routes
export def "services-routes list-routes" [
  serviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Filter for the type of route rule
  --qp-source: list # Filter for the source path of the route
  --destination: list # Filter for the destination path of the route
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<route: record<id: string, type: string, source: string, destination: string, priority: int>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "csv") (serialize-qp "source" $qp_source "csv") (serialize-qp "destination" $destination "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/routes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add redirect/rewrite rules
#
# POST /services/{serviceId}/routes
# operationId: add-route
export def "services-routes add-route" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-1
  --body-source: string # e.g. /:bar/foo
  destination: string # e.g. /foo/:bar
  --priority: int # Redirect and Rewrite Rules are applied in priority order starting at 0. Defaults to last in the priority list.
]: any -> record<id: string, type: string, source: string, destination: string, priority: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/routes")
  let body = {type: $type, source: $body_source, destination: $destination, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update redirect/rewrite rule priority
#
# PATCH /services/{serviceId}/routes
# operationId: patch-route
export def "services-routes patch-route" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  priority: int # Redirect and Rewrite Rules are applied in priority order starting at 0. Moves this route to the specified priority and adjusts other route priorities accordingly.
]: any -> record<headers: record<id: string, type: string, source: string, destination: string, priority: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/routes")
  let body = {priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update redirect/rewrite rules
#
# PUT /services/{serviceId}/routes
# operationId: put-routes
export def "services-routes put-routes" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, type: string, source: string, destination: string, priority: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/routes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete redirect/rewrite rule
#
# DELETE /services/{serviceId}/routes/{routeId}
# operationId: delete-route
export def "services-routes delete-route" [
  serviceId: string
  routeId: string
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
  let full_url = (build-url $base $"/services/($serviceId)/routes/($routeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom domains
#
# GET /services/{serviceId}/custom-domains
# operationId: list-custom-domains
export def "services-custom-domains list-custom-domains" [
  serviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
  --name: list # Filter for the names of custom domain
  --domainType: string@domainType-completer # Filter for domain type
  --verificationStatus: string@verificationStatus-completer # Filter for domain verification status (`verified` or `unverified`)
  --createdBefore: string # Filter for custom domains created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for custom domains created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
]: nothing -> table<customDomain: record<id: string, name: string, domainType: string, publicSuffix: string, redirectForName: string, verificationStatus: string, createdAt: string, server: record>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "csv") (serialize-qp "domainType" $domainType "scalar") (serialize-qp "verificationStatus" $verificationStatus "scalar") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/custom-domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add custom domain
#
# POST /services/{serviceId}/custom-domains
# operationId: create-custom-domain
export def "services-custom-domains create-custom-domain" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> table<id: string, name: string, domainType: string, publicSuffix: string, redirectForName: string, verificationStatus: string, createdAt: string, server: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/custom-domains")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve custom domain
#
# GET /services/{serviceId}/custom-domains/{customDomainIdOrName}
# operationId: retrieve-custom-domain
export def "services-custom-domains retrieve-custom-domain" [
  serviceId: string
  customDomainIdOrName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, domainType: string, publicSuffix: string, redirectForName: string, verificationStatus: string, createdAt: string, server: record<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/custom-domains/($customDomainIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete custom domain
#
# DELETE /services/{serviceId}/custom-domains/{customDomainIdOrName}
# operationId: delete-custom-domain
export def "services-custom-domains delete-custom-domain" [
  serviceId: string
  customDomainIdOrName: string
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
  let full_url = (build-url $base $"/services/($serviceId)/custom-domains/($customDomainIdOrName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify DNS configuration
#
# POST /services/{serviceId}/custom-domains/{customDomainIdOrName}/verify
# operationId: refresh-custom-domain
export def "services-custom-domains-verify refresh-custom-domain" [
  serviceId: string
  customDomainIdOrName: string
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
  let full_url = (build-url $base $"/services/($serviceId)/custom-domains/($customDomainIdOrName)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspend service
#
# POST /services/{serviceId}/suspend
# operationId: suspend-service
export def "services-suspend suspend-service" [
  serviceId: string
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
  let full_url = (build-url $base $"/services/($serviceId)/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume service
#
# POST /services/{serviceId}/resume
# operationId: resume-service
export def "services-resume resume-service" [
  serviceId: string
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
  let full_url = (build-url $base $"/services/($serviceId)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart service
#
# POST /services/{serviceId}/restart
# operationId: restart-service
export def "services-restart restart-service" [
  serviceId: string
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
  let full_url = (build-url $base $"/services/($serviceId)/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Scale instance count
#
# POST /services/{serviceId}/scale
# operationId: scale-service
export def "services-scale scale-service" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  numInstances: int # e.g. 3
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/scale")
  let body = {numInstances: $numInstances} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update autoscaling config
#
# PUT /services/{serviceId}/autoscaling
# operationId: autoscale-service
export def "services-autoscaling autoscale-service" [
  serviceId: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/autoscaling")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete autoscaling config
#
# DELETE /services/{serviceId}/autoscaling
# operationId: delete-autoscaling-config
export def "services-autoscaling delete-autoscaling-config" [
  serviceId: string
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
  let full_url = (build-url $base $"/services/($serviceId)/autoscaling")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create service preview (image-backed)
#
# POST /services/{serviceId}/preview
# operationId: preview-service
export def "services-preview preview-service" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  imagePath: string # Must be either a full URL or the relative path to an image. If a relative path, Render uses the base service's image URL as its root. For example, if the base service's image URL is `docker.io/library/nginx:latest`, then valid values are: `docker.io/library/nginx:<any tag or SHA>`, `library/nginx:<any tag or SHA>`, or `nginx:<any tag or SHA>`. Note that the path must match (only the tag or SHA can vary). (e.g. docker.io/library/nginx:latest)
  --name: string # A name for the service preview instance. If not specified, Render generates the name using the base service's name and the specified tag or SHA. (e.g. preview)
  --plan: string@plan-completer # The instance type to use. Legacy variants (`*_legacy`) identify grandfathered plans no longer offered for new services. Note that base services on any paid instance type can't create preview instances with the `free` instance type. (e.g. starter)
]: any -> record<service: record<id: string, autoDeploy: string, branch: string, buildFilter: record<paths: list, ignoredPaths: list>, createdAt: string, dashboardUrl: string, environmentId: string, imagePath: string, name: string, notifyOnFail: string, ownerId: string, registryCredential: record<id: string, name: string>, repo: string, rootDir: string, slug: string, suspended: string, suspenders: list<string>, type: string, updatedAt: string, serviceDetails: any>, deployId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/preview")
  let body = {imagePath: $imagePath, name: $name, plan: $plan} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List jobs
#
# GET /services/{serviceId}/jobs
# operationId: list-job
export def "services-jobs list-job" [
  serviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
  --status: list # Filter for the status of the job (`pending`, `running`, `succeeded`, `failed`, or `canceled`)
  --createdBefore: string # Filter for jobs created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for jobs created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --startedBefore: string # Filter for jobs started before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --startedAfter: string # Filter for jobs started after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --finishedBefore: string # Filter for jobs finished before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --finishedAfter: string # Filter for jobs finished after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
]: nothing -> table<job: record<id: any, serviceId: string, startCommand: string, planId: string, status: any, createdAt: string, startedAt: string, finishedAt: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "startedBefore" $startedBefore "scalar") (serialize-qp "startedAfter" $startedAfter "scalar") (serialize-qp "finishedBefore" $finishedBefore "scalar") (serialize-qp "finishedAfter" $finishedAfter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($serviceId)/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create job
#
# POST /services/{serviceId}/jobs
# operationId: post-job
export def "services-jobs post-job" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  startCommand: string
  --planId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/jobs")
  let body = {startCommand: $startCommand, planId: $planId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve job
#
# GET /services/{serviceId}/jobs/{jobId}
# operationId: retrieve-job
export def "services-jobs retrieve-job" [
  serviceId: string
  jobId: string
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
  let full_url = (build-url $base $"/services/($serviceId)/jobs/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel running job
#
# POST /services/{serviceId}/jobs/{jobId}/cancel
# operationId: cancel-job
export def "services-jobs-cancel cancel-job" [
  serviceId: string
  jobId: any
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
  let full_url = (build-url $base $"/services/($serviceId)/jobs/($jobId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List instances
#
# GET /services/{serviceId}/instances
# operationId: list-instances
export def "services-instances list-instances" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($serviceId)/instances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger cron job run
#
# POST /cron-jobs/{cronJobId}/runs
# operationId: run-cron-job
export def "cron-jobs-runs run-cron-job" [
  cronJobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, startedAt: string, finishedAt: string, triggeredBy: string, canceledBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cron-jobs/($cronJobId)/runs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel running cron job
#
# DELETE /cron-jobs/{cronJobId}/runs
# operationId: cancel-cron-job-run
export def "cron-jobs-runs cancel-cron-job-run" [
  cronJobId: string
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
  let full_url = (build-url $base $"/cron-jobs/($cronJobId)/runs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve event
#
# GET /events/{eventId}
# operationId: retrieve-event
export def "events retrieve-event" [
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: any, timestamp: string, serviceId: string, type: any, details: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($eventId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List logs
#
# GET /logs
# operationId: list-logs
export def "logs list-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: string # The ID of the workspace to return logs for
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --direction: string@direction-completer # The direction to query logs for. Backward will return most recent logs first. Forward will start with the oldest logs in the time range.  (default: backward)
  --resource: list # Filter logs by their resource. A resource is the id of a server, cronjob, job, postgres, redis, or workflow.
  --instance: list # Filter logs by the instance they were emitted from. An instance is the id of a specific running server.
  --host: list # Filter request logs by their host. [Wildcards and regex](https://render.com/docs/logging#wildcards-and-regular-expressions) are supported.
  --statusCode: list # Filter request logs by their status code. [Wildcards and regex](https://render.com/docs/logging#wildcards-and-regular-expressions) are supported.
  --method: list # Filter request logs by their requests method. [Wildcards and regex](https://render.com/docs/logging#wildcards-and-regular-expressions) are supported.
  --task: list # Filter logs by their task(s)
  --taskRun: list # Filter logs by their task run id(s)
  --level: list # Filter logs by their severity level. [Wildcards and regex](https://render.com/docs/logging#wildcards-and-regular-expressions) are supported.
  --type: list # Filter logs by their type. Types include `app` for application logs, `request` for request logs, and `build` for build logs. You can find the full set of types available for a query by using the `GET /logs/values` endpoint.
  --text: list # Filter by the text of the logs. [Wildcards and regex](https://render.com/docs/logging#wildcards-and-regular-expressions) are supported.
  --path: list # Filter request logs by their path. [Wildcards and regex](https://render.com/docs/logging#wildcards-and-regular-expressions) are supported.
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "resource" $resource "multi") (serialize-qp "instance" $instance "multi") (serialize-qp "host" $host "multi") (serialize-qp "statusCode" $statusCode "multi") (serialize-qp "method" $method "multi") (serialize-qp "task" $task "multi") (serialize-qp "taskRun" $taskRun "multi") (serialize-qp "level" $level "multi") (serialize-qp "type" $type "multi") (serialize-qp "text" $text "multi") (serialize-qp "path" $path "multi") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe to new logs
#
# GET /logs/subscribe
# operationId: subscribe-logs
export def "logs-subscribe subscribe-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: string # The ID of the workspace to return logs for
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs/subscribe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List log label values
#
# GET /logs/values
# operationId: list-logs-values
export def "logs-values list-logs-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: string # The ID of the workspace to return log label values for
  --label: string@label-completer # The label to query logs for
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve log stream
#
# GET /logs/streams/owner/{ownerId}
# operationId: get-owner-log-stream
export def "logs-streams-owner get-owner-log-stream" [
  ownerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ownerId: string, endpoint: string, preview: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/logs/streams/owner/($ownerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update log stream
#
# PUT /logs/streams/owner/{ownerId}
# operationId: update-owner-log-stream
export def "logs-streams-owner update-owner-log-stream" [
  ownerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpoint: string # The endpoint to stream logs to.
  --body-token: string # The optional token to authenticate the log stream.
  preview: string@preview-completer # Whether to send logs or drop them.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/logs/streams/owner/($ownerId)")
  let body = {endpoint: $endpoint, token: $body_token, preview: $preview} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete log stream
#
# DELETE /logs/streams/owner/{ownerId}
# operationId: delete-owner-log-stream
export def "logs-streams-owner delete-owner-log-stream" [
  ownerId: string
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
  let full_url = (build-url $base $"/logs/streams/owner/($ownerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List log stream overrides
#
# GET /logs/streams/resource
# operationId: list-resource-log-streams
export def "logs-streams-resource list-resource-log-streams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: list # The ID of the workspaces to return resources for
  --logStreamId: list # Filter log streams by their id.
  --resourceId: list # IDs of resources (server, cron job, postgres, or redis) to filter by
  --setting: list # Filter log streams by their setting.
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "csv") (serialize-qp "logStreamId" $logStreamId "multi") (serialize-qp "resourceId" $resourceId "multi") (serialize-qp "setting" $setting "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs/streams/resource" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve log stream override
#
# GET /logs/streams/resource/{resourceId}
# operationId: get-resource-log-stream
export def "logs-streams-resource get-resource-log-stream" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resourceId: string, endpoint: string, setting: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/logs/streams/resource/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update log stream override
#
# PUT /logs/streams/resource/{resourceId}
# operationId: update-resource-log-stream
export def "logs-streams-resource update-resource-log-stream" [
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpoint: any
  --body-token: any
  setting: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/logs/streams/resource/($resourceId)")
  let body = {endpoint: $endpoint, token: $body_token, setting: $setting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete log stream override
#
# DELETE /logs/streams/resource/{resourceId}
# operationId: delete-resource-log-stream
export def "logs-streams-resource delete-resource-log-stream" [
  resourceId: string
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
  let full_url = (build-url $base $"/logs/streams/resource/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve metrics stream
#
# GET /metrics-stream/{ownerId}
# operationId: getOwnerMetricsStream
export def "metrics-stream get" [
  ownerId: string
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
  let full_url = (build-url $base $"/metrics-stream/($ownerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update metrics stream
#
# PUT /metrics-stream/{ownerId}
# operationId: upsertOwnerMetricsStream
export def "metrics-stream upsertOwnerMetricsStream" [
  ownerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --provider: string@provider-completer # Provider to send metrics to
  --body-url: string # The endpoint URL to stream metrics to
  --body-token: string # Authentication token for the metrics stream
]: any -> record<ownerId: string, provider: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/metrics-stream/($ownerId)")
  let body = {provider: $provider, url: $body_url, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete metrics stream
#
# DELETE /metrics-stream/{ownerId}
# operationId: deleteOwnerMetricsStream
export def "metrics-stream delete" [
  ownerId: string
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
  let full_url = (build-url $base $"/metrics-stream/($ownerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CPU usage
#
# GET /metrics/cpu
# operationId: get-cpu
@deprecated --flag service
export def "metrics-cpu get-cpu" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --resolutionSeconds: float # The resolution of the returned data (default: 60, e.g. 60)
  --resource: string # Resource ID to query. When multiple resource query params are provided, they are ORed together. Resources can be service ids, Postgres ids, or Redis ids (e.g. srv-xxxxx,dpg-xxxxx,red-xxxxx)
  --service: string # This parameter is deprecated. Please use `resource` instead (DEPRECATED, e.g. srv-xxxxx)
  --instance: string # Instance ID to query. When multiple instance ID query params are provided, they are ORed together (e.g. srv-xxxxx-yyyy)
  --aggregationMethod: string@aggregationMethod-completer # The aggregation method to apply to multiple time series
]: nothing -> table<labels: list<record>, values: list<record>, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "resolutionSeconds" $resolutionSeconds "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "instance" $instance "scalar") (serialize-qp "aggregationMethod" $aggregationMethod "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/cpu" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CPU limit
#
# GET /metrics/cpu-limit
# operationId: get-cpu-limit
export def "metrics-cpu-limit get-cpu-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/cpu-limit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get CPU target
#
# GET /metrics/cpu-target
# operationId: get-cpu-target
export def "metrics-cpu-target get-cpu-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/cpu-target" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get memory usage
#
# GET /metrics/memory
# operationId: get-memory
export def "metrics-memory get-memory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/memory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get memory limit
#
# GET /metrics/memory-limit
# operationId: get-memory-limit
export def "metrics-memory-limit get-memory-limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/memory-limit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get memory target
#
# GET /metrics/memory-target
# operationId: get-memory-target
export def "metrics-memory-target get-memory-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/memory-target" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get HTTP request count
#
# GET /metrics/http-requests
# operationId: get-http-requests
export def "metrics-http-requests get-http-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --aggregateBy: string@aggregateBy-completer # The field to aggregate by
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "aggregateBy" $aggregateBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/http-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get HTTP latency
#
# GET /metrics/http-latency
# operationId: get-http-latency
export def "metrics-http-latency get-http-latency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --host: string # The hosts of HTTP requests to filter to. When multiple host query params are provided, they are ORed together (e.g. example.com)
  --path: string # The paths of HTTP requests to filter to. When multiple path query params are provided, they are ORed together (e.g. /graphql)
  --quantile: float # The quantile of latencies to fetch. When multiple quantile query params are provided, they are ORed together (format: float, e.g. 0.99)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "quantile" $quantile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/http-latency" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get bandwidth usage
#
# GET /metrics/bandwidth
# operationId: get-bandwidth
export def "metrics-bandwidth get-bandwidth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --resource: string # Service ID to query. When multiple service ids are provided, they are ORed together (e.g. srv-xxxxx)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/bandwidth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get bandwidth usage breakdown by traffic source
#
# GET /metrics/bandwidth-sources
# operationId: get-bandwidth-sources
export def "metrics-bandwidth-sources get-bandwidth-sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> record<data: table<labels: record, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/bandwidth-sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get disk usage
#
# GET /metrics/disk-usage
# operationId: get-disk-usage
export def "metrics-disk-usage get-disk-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/disk-usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get disk capacity
#
# GET /metrics/disk-capacity
# operationId: get-disk-capacity
export def "metrics-disk-capacity get-disk-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/disk-capacity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get instance count
#
# GET /metrics/instance-count
# operationId: get-instance-count
export def "metrics-instance-count get-instance-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/instance-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get active connection count
#
# GET /metrics/active-connections
# operationId: get-active-connections
export def "metrics-active-connections get-active-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --resource: string # Resource ID to query. When multiple resource query params are provided, they are ORed together. Resources Postgres ids or Redis ids (e.g. dpg-xxxxx,red-xxxxx)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/active-connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get replica lag
#
# GET /metrics/replication-lag
# operationId: get-replication-lag
export def "metrics-replication-lag get-replication-lag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --resource: string # Postgres ID to query. When multiple resource query params are provided, they are ORed together (e.g. dpg-xxxxx)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/replication-lag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List queryable instance values
#
# GET /metrics/filters/application
# operationId: list-application-filter-values
export def "metrics-filters-application list-application-filter-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> table<filter: string, values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/filters/application" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List queryable status codes and host values
#
# GET /metrics/filters/http
# operationId: list-http-filter-values
export def "metrics-filters-http list-http-filter-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --statusCode: string # The status codes of HTTP requests to filter to. When multiple status code query params are provided, they are ORed together (e.g. 200)
]: nothing -> table<filter: string, values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "statusCode" $statusCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/filters/http" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List queryable paths
#
# GET /metrics/filters/path
# operationId: list-path-filter-values
export def "metrics-filters-path list-path-filter-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/filters/path" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get task runs queued count
#
# GET /metrics/task-runs-queued
# operationId: get-task-runs-queued
export def "metrics-task-runs-queued get-task-runs-queued" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --resource: string # Task ID to query. When multiple task IDs are provided, they are ORed together (e.g. tsk-xxxxx)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/task-runs-queued" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get task runs completed count
#
# GET /metrics/task-runs-completed
# operationId: get-task-runs-completed
export def "metrics-task-runs-completed get-task-runs-completed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # Epoch/Unix timestamp of start of time range to return. Defaults to `now() - 1 hour`. (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --endTime: string # Epoch/Unix timestamp of end of time range to return. Defaults to `now()`. (format: date-time, e.g. 2021-06-17T08:30:30Z)
  --state: string@state-completer # The state of task runs to filter to. When multiple state query params are provided, they are ORed together
  --aggregateBy: string@aggregateBy-completer-1 # The field to aggregate by
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "aggregateBy" $aggregateBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/task-runs-completed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Key Value instances
#
# GET /key-value
# operationId: list-key-value
export def "key-value list-key-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --region: list # Filter by resource region
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --environmentId: list # Filter for resources that belong to an environment
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<keyValue: record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record, options: record, ipAllowList: list, environmentId: string, version: string, dashboardUrl: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "region" $region "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "environmentId" $environmentId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/key-value" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Key Value instance
#
# POST /key-value
# operationId: create-key-value
# --ipAllowList item shape: {cidrBlock: string, description: string}
export def "key-value create-key-value" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the Key Value instance
  ownerId: string # The ID of the owner of the Key Value instance
  plan: string@plan-completer-1
  --region: string@region-completer # Defaults to "oregon" (default: oregon)
  --environmentId: string
  --maxmemoryPolicy: string@maxmemoryPolicy-completer # The eviction policy for the Key Value instance
  --persistenceMode: string@persistenceMode-completer # The persistence mode for the Key Value instance. The default for paid instances is journal_snapshot (both journaling and snapshots). Only turn off persistence if you're using this Key Value instance as a cache and are okay with losing data. Free instances do not have persistence.
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
]: any -> record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, options: record<maxmemoryPolicy: string, persistenceMode: string>, ipAllowList: table<cidrBlock: string, description: string>, environmentId: string, version: string, maintenance: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/key-value")
  let body = {name: $name, ownerId: $ownerId, plan: $plan, region: $region, environmentId: $environmentId, maxmemoryPolicy: $maxmemoryPolicy, persistenceMode: $persistenceMode, ipAllowList: $ipAllowList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Key Value instance
#
# GET /key-value/{keyValueId}
# operationId: retrieve-key-value
export def "key-value retrieve-key-value" [
  keyValueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, options: record<maxmemoryPolicy: string, persistenceMode: string>, ipAllowList: table<cidrBlock: string, description: string>, environmentId: string, version: string, maintenance: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/key-value/($keyValueId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Key Value instance
#
# PATCH /key-value/{keyValueId}
# operationId: update-key-value
# --ipAllowList item shape: {cidrBlock: string, description: string}
export def "key-value update-key-value" [
  keyValueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the Key Value instance
  --plan: string@plan-completer-1
  --maxmemoryPolicy: string@maxmemoryPolicy-completer # The eviction policy for the Key Value instance
  --persistenceMode: string@persistenceMode-completer # The persistence mode for the Key Value instance. The default for paid instances is journal_snapshot (both journaling and snapshots). Only turn off persistence if you're using this Key Value instance as a cache and are okay with losing data. Free instances do not have persistence.
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
]: any -> record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, options: record<maxmemoryPolicy: string, persistenceMode: string>, ipAllowList: table<cidrBlock: string, description: string>, environmentId: string, version: string, maintenance: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/key-value/($keyValueId)")
  let body = {name: $name, plan: $plan, maxmemoryPolicy: $maxmemoryPolicy, persistenceMode: $persistenceMode, ipAllowList: $ipAllowList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Key Value instance
#
# DELETE /key-value/{keyValueId}
# operationId: delete-key-value
export def "key-value delete-key-value" [
  keyValueId: string
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
  let full_url = (build-url $base $"/key-value/($keyValueId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Key Value connection info
#
# GET /key-value/{keyValueId}/connection-info
# operationId: retrieve-key-value-connection-info
export def "key-value-connection-info retrieve-key-value-connection-info" [
  keyValueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<internalConnectionString: string, externalConnectionString: string, cliCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/key-value/($keyValueId)/connection-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspend Key Value instance
#
# POST /key-value/{keyValueId}/suspend
# operationId: suspend-key-value
export def "key-value-suspend suspend-key-value" [
  keyValueId: string
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
  let full_url = (build-url $base $"/key-value/($keyValueId)/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume Key Value instance
#
# POST /key-value/{keyValueId}/resume
# operationId: resume-key-value
export def "key-value-resume resume-key-value" [
  keyValueId: string
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
  let full_url = (build-url $base $"/key-value/($keyValueId)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Redis instances
#
# GET /redis
# DEPRECATED
# operationId: list-redis
@deprecated
export def "redis list-redis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --region: list # Filter by resource region
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --environmentId: list # Filter for resources that belong to an environment
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<redis: record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record, options: record, ipAllowList: list, environmentId: string, version: string, dashboardUrl: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "region" $region "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "environmentId" $environmentId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/redis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Redis instance
#
# POST /redis
# DEPRECATED
# operationId: create-redis
# --ipAllowList item shape: {cidrBlock: string, description: string}
@deprecated
export def "redis create-redis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the Redis instance
  ownerId: string # The ID of the owner of the Redis instance
  plan: string@plan-completer-1
  --region: string@region-completer # Defaults to "oregon" (default: oregon)
  --environmentId: string
  --maxmemoryPolicy: string@maxmemoryPolicy-completer # The eviction policy for the Key Value instance
  --persistenceMode: string@persistenceMode-completer # The persistence mode for the Key Value instance. The default for paid instances is journal_snapshot (both journaling and snapshots). Only turn off persistence if you're using this Key Value instance as a cache and are okay with losing data. Free instances do not have persistence.
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
]: any -> record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, options: record<maxmemoryPolicy: string, persistenceMode: string>, ipAllowList: table<cidrBlock: string, description: string>, environmentId: string, version: string, maintenance: record<id: any, type: string, scheduledAt: string, pendingMaintenanceBy: string, state: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/redis")
  let body = {name: $name, ownerId: $ownerId, plan: $plan, region: $region, environmentId: $environmentId, maxmemoryPolicy: $maxmemoryPolicy, persistenceMode: $persistenceMode, ipAllowList: $ipAllowList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Redis instance
#
# GET /redis/{redisId}
# DEPRECATED
# operationId: retrieve-redis
@deprecated
export def "redis retrieve-redis" [
  redisId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, options: record<maxmemoryPolicy: string, persistenceMode: string>, ipAllowList: table<cidrBlock: string, description: string>, environmentId: string, version: string, maintenance: record<id: any, type: string, scheduledAt: string, pendingMaintenanceBy: string, state: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/redis/($redisId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Redis instance
#
# PATCH /redis/{redisId}
# DEPRECATED
# operationId: update-redis
# --ipAllowList item shape: {cidrBlock: string, description: string}
@deprecated
export def "redis update-redis" [
  redisId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the Redis instance
  --plan: string@plan-completer-1
  --maxmemoryPolicy: string@maxmemoryPolicy-completer # The eviction policy for the Key Value instance
  --persistenceMode: string@persistenceMode-completer # The persistence mode for the Key Value instance. The default for paid instances is journal_snapshot (both journaling and snapshots). Only turn off persistence if you're using this Key Value instance as a cache and are okay with losing data. Free instances do not have persistence.
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
]: any -> record<id: string, createdAt: string, updatedAt: string, status: string, region: string, plan: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, options: record<maxmemoryPolicy: string, persistenceMode: string>, ipAllowList: table<cidrBlock: string, description: string>, environmentId: string, version: string, maintenance: record<id: any, type: string, scheduledAt: string, pendingMaintenanceBy: string, state: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/redis/($redisId)")
  let body = {name: $name, plan: $plan, maxmemoryPolicy: $maxmemoryPolicy, persistenceMode: $persistenceMode, ipAllowList: $ipAllowList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Redis instance
#
# DELETE /redis/{redisId}
# DEPRECATED
# operationId: delete-redis
@deprecated
export def "redis delete-redis" [
  redisId: string
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
  let full_url = (build-url $base $"/redis/($redisId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Redis connection info
#
# GET /redis/{redisId}/connection-info
# DEPRECATED
# operationId: retrieve-redis-connection-info
@deprecated
export def "redis-connection-info retrieve-redis-connection-info" [
  redisId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<internalConnectionString: string, externalConnectionString: string, redisCLICommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/redis/($redisId)/connection-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Postgres instances
#
# GET /postgres
# operationId: list-postgres
export def "postgres list-postgres" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --region: list # Filter by resource region
  --suspended: list # Filter resources based on whether they're suspended or not suspended
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --environmentId: list # Filter for resources that belong to an environment
  --includeReplicas: oneof<nothing, bool> # Include replicas in the response (default: true)
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<postgres: record<id: string, ipAllowList: list, createdAt: string, updatedAt: string, expiresAt: string, databaseName: string, databaseUser: string, environmentId: string, highAvailabilityEnabled: bool, name: string, owner: record, plan: string, diskSizeGB: int, primaryPostgresID: string, region: string, readReplicas: list, role: string, status: string, version: string, suspended: string, suspenders: list, dashboardUrl: string, diskAutoscalingEnabled: bool>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "region" $region "csv") (serialize-qp "suspended" $suspended "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "environmentId" $environmentId "csv") (serialize-qp "includeReplicas" $includeReplicas "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/postgres" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Postgres instance
#
# POST /postgres
# operationId: create-postgres
# --ipAllowList item shape: {cidrBlock: string, description: string}
# --readReplicas item shape: {name: string, parameterOverrides?: record}
export def "postgres create-postgres" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --databaseName: string # default: randomly generated
  --databaseUser: string # default: randomly generated
  --datadogAPIKey: string # The Datadog API key for the Datadog agent to monitor the new database.
  --datadogSite: string # Datadog region to use for monitoring the new database. Defaults to 'US1'. (e.g. US1)
  name: string # The name of the database as it will appear in the Render Dashboard
  --enableHighAvailability: oneof<nothing, bool> # default: false
  --environmentId: string
  ownerId: string # The ID of the workspace to create the database for
  plan: string@plan-completer # The instance type to use. Legacy variants (`*_legacy`) identify grandfathered plans no longer offered for new services. Note that base services on any paid instance type can't create preview instances with the `free` instance type. (e.g. starter)
  --diskSizeGB: int # The number of gigabytes of disk space to allocate for the database
  --enableDiskAutoscaling: oneof<nothing, bool> # default: false
  --region: string@region-completer # Defaults to "oregon" (default: oregon)
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
  --parameterOverrides: record
  --readReplicas: list # item shape: {name: string, parameterOverrides?: record}
  version: string@version-completer # The PostgreSQL version
]: any -> record<id: string, ipAllowList: table<cidrBlock: string, description: string>, createdAt: string, updatedAt: string, expiresAt: string, dashboardUrl: string, databaseName: string, databaseUser: string, environmentId: string, highAvailabilityEnabled: bool, maintenance: any, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, plan: string, diskSizeGB: int, parameterOverrides: record, primaryPostgresID: string, region: string, readReplicas: table<id: string, name: string, parameterOverrides: record>, role: string, status: string, version: string, suspended: string, suspenders: list<string>, diskAutoscalingEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/postgres")
  let body = {databaseName: $databaseName, databaseUser: $databaseUser, datadogAPIKey: $datadogAPIKey, datadogSite: $datadogSite, name: $name, enableHighAvailability: $enableHighAvailability, environmentId: $environmentId, ownerId: $ownerId, plan: $plan, diskSizeGB: $diskSizeGB, enableDiskAutoscaling: $enableDiskAutoscaling, region: $region, ipAllowList: $ipAllowList, parameterOverrides: $parameterOverrides, readReplicas: $readReplicas, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Postgres instance
#
# GET /postgres/{postgresId}
# operationId: retrieve-postgres
export def "postgres retrieve-postgres" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, ipAllowList: table<cidrBlock: string, description: string>, createdAt: string, updatedAt: string, expiresAt: string, dashboardUrl: string, databaseName: string, databaseUser: string, environmentId: string, highAvailabilityEnabled: bool, maintenance: any, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, plan: string, diskSizeGB: int, parameterOverrides: record, primaryPostgresID: string, region: string, readReplicas: table<id: string, name: string, parameterOverrides: record>, role: string, status: string, version: string, suspended: string, suspenders: list<string>, diskAutoscalingEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Postgres instance
#
# PATCH /postgres/{postgresId}
# operationId: update-postgres
# --ipAllowList item shape: {cidrBlock: string, description: string}
# --readReplicas item shape: {name: string, parameterOverrides?: record}
export def "postgres update-postgres" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --plan: string@plan-completer # The instance type to use. Legacy variants (`*_legacy`) identify grandfathered plans no longer offered for new services. Note that base services on any paid instance type can't create preview instances with the `free` instance type. (e.g. starter)
  --diskSizeGB: int # The number of gigabytes of disk space to allocate for the database
  --enableDiskAutoscaling: oneof<nothing, bool>
  --enableHighAvailability: oneof<nothing, bool>
  --datadogAPIKey: string # The Datadog API key for the Datadog agent to monitor the database. Pass empty string to remove. Restarts Postgres on change.
  --datadogSite: string # Datadog region to use for monitoring the new database. Defaults to 'US1'. (e.g. US1)
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
  --parameterOverrides: record
  --readReplicas: list # item shape: {name: string, parameterOverrides?: record}
]: any -> record<id: string, ipAllowList: table<cidrBlock: string, description: string>, createdAt: string, updatedAt: string, expiresAt: string, dashboardUrl: string, databaseName: string, databaseUser: string, environmentId: string, highAvailabilityEnabled: bool, maintenance: any, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, plan: string, diskSizeGB: int, parameterOverrides: record, primaryPostgresID: string, region: string, readReplicas: table<id: string, name: string, parameterOverrides: record>, role: string, status: string, version: string, suspended: string, suspenders: list<string>, diskAutoscalingEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)")
  let body = {name: $name, plan: $plan, diskSizeGB: $diskSizeGB, enableDiskAutoscaling: $enableDiskAutoscaling, enableHighAvailability: $enableHighAvailability, datadogAPIKey: $datadogAPIKey, datadogSite: $datadogSite, ipAllowList: $ipAllowList, parameterOverrides: $parameterOverrides, readReplicas: $readReplicas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Postgres instance
#
# DELETE /postgres/{postgresId}
# operationId: delete-postgres
export def "postgres delete-postgres" [
  postgresId: string
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
  let full_url = (build-url $base $"/postgres/($postgresId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Postgres connection info
#
# GET /postgres/{postgresId}/connection-info
# operationId: retrieve-postgres-connection-info
export def "postgres-connection-info retrieve-postgres-connection-info" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<password: string, internalConnectionString: string, externalConnectionString: string, psqlCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)/connection-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve point-in-time recovery status
#
# GET /postgres/{postgresId}/recovery
# operationId: retrieve-postgres-recovery-info
export def "postgres-recovery retrieve-postgres-recovery-info" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recoveryStatus: string, startsAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)/recovery")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger point-in-time recovery
#
# POST /postgres/{postgresId}/recovery
# operationId: recover-postgres
export def "postgres-recovery recover-postgres" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --restoreName: string # Name of the new database.
  restoreTime: string # The point in time to restore the database to. See `/recovery-info` for restore availability (format: date-time)
  --datadogApiKey: string # Datadog API key to use for monitoring the new database. Defaults to the API key of the original database. Use an empty string to prevent copying of the API key to the new database.
  --datadogSite: string # Datadog region code to use for monitoring the new database. Defaults to the region code of the original database. Use an empty string to prevent copying of the region code to the new database.
  --plan: string # The plan to use for the new database. Defaults to the same plan as the original database. Cannot be a lower tier plan than the original database.
  --environmentId: string # The environment to create the new database in. Defaults to the environment of the original database.
]: any -> record<id: string, ipAllowList: table<cidrBlock: string, description: string>, createdAt: string, updatedAt: string, expiresAt: string, dashboardUrl: string, databaseName: string, databaseUser: string, environmentId: string, highAvailabilityEnabled: bool, maintenance: any, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, plan: string, diskSizeGB: int, parameterOverrides: record, primaryPostgresID: string, region: string, readReplicas: table<id: string, name: string, parameterOverrides: record>, role: string, status: string, version: string, suspended: string, suspenders: list<string>, diskAutoscalingEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)/recovery")
  let body = {restoreName: $restoreName, restoreTime: $restoreTime, datadogApiKey: $datadogApiKey, datadogSite: $datadogSite, plan: $plan, environmentId: $environmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Suspend Postgres instance
#
# POST /postgres/{postgresId}/suspend
# operationId: suspend-postgres
export def "postgres-suspend suspend-postgres" [
  postgresId: string
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
  let full_url = (build-url $base $"/postgres/($postgresId)/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume Postgres instance
#
# POST /postgres/{postgresId}/resume
# operationId: resume-postgres
export def "postgres-resume resume-postgres" [
  postgresId: string
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
  let full_url = (build-url $base $"/postgres/($postgresId)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart Postgres instance
#
# POST /postgres/{postgresId}/restart
# operationId: restart-postgres
export def "postgres-restart restart-postgres" [
  postgresId: string
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
  let full_url = (build-url $base $"/postgres/($postgresId)/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Failover Postgres instance
#
# POST /postgres/{postgresId}/failover
# operationId: failover-postgres
export def "postgres-failover failover-postgres" [
  postgresId: string
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
  let full_url = (build-url $base $"/postgres/($postgresId)/failover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Postgres exports
#
# GET /postgres/{postgresId}/export
# operationId: list-postgres-export
export def "postgres-export list-postgres-export" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, createdAt: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Postgres export
#
# POST /postgres/{postgresId}/export
# operationId: create-postgres-export
export def "postgres-export create-postgres-export" [
  postgresId: string
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
  let full_url = (build-url $base $"/postgres/($postgresId)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List PostgreSQL Users
#
# GET /postgres/{postgresId}/credentials
# operationId: list-postgres-users
export def "postgres-credentials list-postgres-users" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<username: string, default: bool, createdAt: string, openConnections: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create PostgreSQL User
#
# POST /postgres/{postgresId}/credentials
# operationId: create-postgres-user
export def "postgres-credentials create-postgres-user" [
  postgresId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # Name of the new user.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/postgres/($postgresId)/credentials")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete PostgreSQL User
#
# DELETE /postgres/{postgresId}/credentials/{username}
# operationId: delete-postgres-user
export def "postgres-credentials delete-postgres-user" [
  postgresId: string
  username: string
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
  let full_url = (build-url $base $"/postgres/($postgresId)/credentials/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List projects
#
# GET /projects
# operationId: list-projects
export def "projects list-projects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<project: record<id: string, createdAt: string, updatedAt: string, name: string, owner: record, environmentIds: list>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create project
#
# POST /projects
# operationId: create-project
# --environments item shape: {name: string, protectedStatus?: "unprotected"|"protected", networkIsolationEnabled?: bool, ipAllowList?: list}
export def "projects create-project" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the project
  ownerId: string # The ID of the owner that the project belongs to
  environments: list # The environments to create when creating the project — item shape: {name: string, protectedStatus?: "unprotected"|"protected", networkIsolationEnabled?: bool, ipAllowList?: list}
]: any -> record<id: string, createdAt: string, updatedAt: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, environmentIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {name: $name, ownerId: $ownerId, environments: $environments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Project
#
# GET /projects/{projectId}
# operationId: retrieve-project
export def "projects retrieve-project" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, environmentIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update project
#
# PATCH /projects/{projectId}
# operationId: update-project
export def "projects update-project" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> record<id: string, createdAt: string, updatedAt: string, name: string, owner: record<id: string, name: string, email: string, ipAllowList: list<record>, twoFactorAuthEnabled: bool, type: string>, environmentIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete project
#
# DELETE /projects/{projectId}
# operationId: delete-project
export def "projects delete-project" [
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create environment
#
# POST /environments
# operationId: create-environment
# --ipAllowList item shape: {cidrBlock: string, description: string}
export def "environments create-environment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  projectId: string
  --protectedStatus: string@protectedStatus-completer # Indicates whether an environment is `unprotected` or `protected`. Only admin users can perform destructive actions in `protected` environments.
  --networkIsolationEnabled: oneof<nothing, bool> # Indicates whether network connections across environments are allowed.
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
]: any -> record<id: string, name: string, projectId: string, databasesIds: list<string>, ipAllowList: table<cidrBlock: string, description: string>, redisIds: list<string>, serviceIds: list<string>, envGroupIds: list<string>, protectedStatus: string, networkIsolationEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let body = {name: $name, projectId: $projectId, protectedStatus: $protectedStatus, networkIsolationEnabled: $networkIsolationEnabled, ipAllowList: $ipAllowList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List environments
#
# GET /environments
# operationId: list-environments
export def "environments list-environments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --projectId: list # Filter for resources that belong to a project
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --environmentId: list # Filter for resources that belong to an environment
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<environment: record<id: string, name: string, projectId: string, databasesIds: list, ipAllowList: list, redisIds: list, serviceIds: list, envGroupIds: list, protectedStatus: string, networkIsolationEnabled: bool>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "projectId" $projectId "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "environmentId" $environmentId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve environment
#
# GET /environments/{environmentId}
# operationId: retrieve-environment
export def "environments retrieve-environment" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, projectId: string, databasesIds: list<string>, ipAllowList: table<cidrBlock: string, description: string>, redisIds: list<string>, serviceIds: list<string>, envGroupIds: list<string>, protectedStatus: string, networkIsolationEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update environment
#
# PATCH /environments/{environmentId}
# operationId: update-environment
# --ipAllowList item shape: {cidrBlock: string, description: string}
export def "environments update-environment" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --networkIsolationEnabled: oneof<nothing, bool> # Indicates whether network connections across environments are allowed.
  --protectedStatus: string@protectedStatus-completer # Indicates whether an environment is `unprotected` or `protected`. Only admin users can perform destructive actions in `protected` environments.
  --ipAllowList: list # item shape: {cidrBlock: string, description: string}
]: any -> record<id: string, name: string, projectId: string, databasesIds: list<string>, ipAllowList: table<cidrBlock: string, description: string>, redisIds: list<string>, serviceIds: list<string>, envGroupIds: list<string>, protectedStatus: string, networkIsolationEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentId)")
  let body = {name: $name, networkIsolationEnabled: $networkIsolationEnabled, protectedStatus: $protectedStatus, ipAllowList: $ipAllowList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete environment
#
# DELETE /environments/{environmentId}
# operationId: delete-environment
export def "environments delete-environment" [
  environmentId: string
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
  let full_url = (build-url $base $"/environments/($environmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add resources to environment
#
# POST /environments/{environmentId}/resources
# operationId: add-resources-to-environment
export def "environments-resources add-resources-to-environment" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resourceIds: list
]: any -> record<id: string, name: string, projectId: string, databasesIds: list<string>, ipAllowList: table<cidrBlock: string, description: string>, redisIds: list<string>, serviceIds: list<string>, envGroupIds: list<string>, protectedStatus: string, networkIsolationEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentId)/resources")
  let body = {resourceIds: $resourceIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove resources from environment
#
# DELETE /environments/{environmentId}/resources
# operationId: remove-resources-from-environment
export def "environments-resources remove-resources-from-environment" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceIds: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceIds" $resourceIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentId)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List environment groups
#
# GET /env-groups
# operationId: list-env-groups
export def "env-groups list-env-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --createdBefore: string # Filter for resources created before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --createdAfter: string # Filter for resources created after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --updatedBefore: string # Filter for resources updated before a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --updatedAfter: string # Filter for resources updated after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --ownerId: list # The ID of the workspaces to return resources for
  --environmentId: list # Filter for resources that belong to an environment
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, serviceLinks: list<record>, environmentId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "updatedBefore" $updatedBefore "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "environmentId" $environmentId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/env-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create environment group
#
# POST /env-groups
# operationId: create-env-group
# --secretFiles item shape: {name: string, content: string}
export def "env-groups create-env-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  ownerId: string
  envVars: any
  --secretFiles: list # item shape: {name: string, content: string}
  --serviceIds: list
  --environmentId: string
]: any -> record<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, serviceLinks: table<id: string, name: string, type: string>, environmentId: string, envVars: table<key: string, value: string>, secretFiles: table<name: string, content: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/env-groups")
  let body = {name: $name, ownerId: $ownerId, envVars: $envVars, secretFiles: $secretFiles, serviceIds: $serviceIds, environmentId: $environmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve environment group
#
# GET /env-groups/{envGroupId}
# operationId: retrieve-env-group
export def "env-groups retrieve-env-group" [
  envGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, serviceLinks: table<id: string, name: string, type: string>, environmentId: string, envVars: table<key: string, value: string>, secretFiles: table<name: string, content: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-groups/($envGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update environment group
#
# PATCH /env-groups/{envGroupId}
# operationId: update-env-group
export def "env-groups update-env-group" [
  envGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, serviceLinks: table<id: string, name: string, type: string>, environmentId: string, envVars: table<key: string, value: string>, secretFiles: table<name: string, content: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-groups/($envGroupId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete environment group
#
# DELETE /env-groups/{envGroupId}
# operationId: delete-env-group
export def "env-groups delete-env-group" [
  envGroupId: string
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
  let full_url = (build-url $base $"/env-groups/($envGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link service
#
# POST /env-groups/{envGroupId}/services/{serviceId}
# operationId: link-service-to-env-group
export def "env-groups-services link-service-to-env-group" [
  envGroupId: string
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, serviceLinks: table<id: string, name: string, type: string>, environmentId: string, envVars: table<key: string, value: string>, secretFiles: table<name: string, content: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-groups/($envGroupId)/services/($serviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlink service
#
# DELETE /env-groups/{envGroupId}/services/{serviceId}
# operationId: unlink-service-from-env-group
export def "env-groups-services unlink-service-from-env-group" [
  envGroupId: string
  serviceId: string
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
  let full_url = (build-url $base $"/env-groups/($envGroupId)/services/($serviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve environment variable
#
# GET /env-groups/{envGroupId}/env-vars/{envVarKey}
# operationId: retrieve-env-group-env-var
export def "env-groups-env-vars retrieve-env-group-env-var" [
  envGroupId: string
  envVarKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-groups/($envGroupId)/env-vars/($envVarKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update environment variable
#
# PUT /env-groups/{envGroupId}/env-vars/{envVarKey}
# operationId: update-env-group-env-var
export def "env-groups-env-vars update-env-group-env-var" [
  envGroupId: string
  envVarKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: string
  --generateValue: oneof<nothing, bool>
]: any -> record<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, serviceLinks: table<id: string, name: string, type: string>, environmentId: string, envVars: table<key: string, value: string>, secretFiles: table<name: string, content: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-groups/($envGroupId)/env-vars/($envVarKey)")
  let body = {value: $value, generateValue: $generateValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove environment variable
#
# DELETE /env-groups/{envGroupId}/env-vars/{envVarKey}
# operationId: delete-env-group-env-var
export def "env-groups-env-vars delete-env-group-env-var" [
  envGroupId: string
  envVarKey: string
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
  let full_url = (build-url $base $"/env-groups/($envGroupId)/env-vars/($envVarKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve secret file
#
# GET /env-groups/{envGroupId}/secret-files/{secretFileName}
# operationId: retrieve-env-group-secret-file
export def "env-groups-secret-files retrieve-env-group-secret-file" [
  envGroupId: string
  secretFileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-groups/($envGroupId)/secret-files/($secretFileName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or update secret file
#
# PUT /env-groups/{envGroupId}/secret-files/{secretFileName}
# operationId: update-env-group-secret-file
export def "env-groups-secret-files update-env-group-secret-file" [
  envGroupId: string
  secretFileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string
]: any -> record<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, serviceLinks: table<id: string, name: string, type: string>, environmentId: string, envVars: table<key: string, value: string>, secretFiles: table<name: string, content: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/env-groups/($envGroupId)/secret-files/($secretFileName)")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove secret file
#
# DELETE /env-groups/{envGroupId}/secret-files/{secretFileName}
# operationId: delete-env-group-secret-file
export def "env-groups-secret-files delete-env-group-secret-file" [
  envGroupId: string
  secretFileName: string
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
  let full_url = (build-url $base $"/env-groups/($envGroupId)/secret-files/($secretFileName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List maintenance runs
#
# GET /maintenance
# operationId: list-maintenance
export def "maintenance list-maintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resourceId: list
  --ownerId: list # The ID of the workspaces to return resources for
  --state: list
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceId" $resourceId "csv") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "state" $state "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/maintenance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve maintenance run
#
# GET /maintenance/{maintenanceRunParam}
# operationId: retrieve-maintenance
export def "maintenance retrieve-maintenance" [
  maintenanceRunParam: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: any, type: string, scheduledAt: string, pendingMaintenanceBy: string, state: any, resourceId: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance/($maintenanceRunParam)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update maintenance run
#
# PATCH /maintenance/{maintenanceRunParam}
# operationId: update-maintenance
export def "maintenance update-maintenance" [
  maintenanceRunParam: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduledAt: string # The date-time at which the maintenance is scheduled to start. This must be before the pendingMaintenanceBy date-time. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/maintenance/($maintenanceRunParam)")
  let body = {scheduledAt: $scheduledAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger maintenance run
#
# POST /maintenance/{maintenanceRunParam}/trigger
# operationId: trigger-maintenance
export def "maintenance-trigger trigger-maintenance" [
  maintenanceRunParam: any
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
  let full_url = (build-url $base $"/maintenance/($maintenanceRunParam)/trigger")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /webhooks
# operationId: create-webhook
export def "webhooks create-webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ownerId: string # The ID of the owner (team or personal user) whose resources should be returned
  --body-url: string
  name: string
  --enabled: oneof<nothing, bool>
  eventFilter: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {ownerId: $ownerId, url: $body_url, name: $name, enabled: $enabled, eventFilter: $eventFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List webhooks
#
# GET /webhooks
# operationId: list-webhooks
export def "webhooks list-webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
  --ownerId: list # The ID of the workspaces to return resources for
]: nothing -> table<webhook: record<id: any, url: string, name: string, secret: string, enabled: bool, eventFilter: list>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ownerId" $ownerId "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a webhook
#
# GET /webhooks/{webhookId}
# operationId: retrieve-webhook
export def "webhooks retrieve-webhook" [
  webhookId: string
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
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /webhooks/{webhookId}
# operationId: update-webhook
export def "webhooks update-webhook" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --body-url: string
  --enabled: oneof<nothing, bool>
  --eventFilter: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let body = {name: $name, url: $body_url, enabled: $enabled, eventFilter: $eventFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /webhooks/{webhookId}
# operationId: delete-webhook
export def "webhooks delete-webhook" [
  webhookId: string
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
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhook events
#
# GET /webhooks/{webhookId}/events
# operationId: list-webhook-events
export def "webhooks-events list-webhook-events" [
  webhookId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sentBefore: string # Filter events sent before this time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-06-17T08:15:30Z)
  --sentAfter: string # Filter for resources sent after a certain time (specified as an ISO 8601 timestamp) (format: date-time, e.g. 2021-02-17T08:15:30Z)
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
]: nothing -> table<webhookEvent: record<id: string, eventId: string, eventType: string, sentAt: string, statusCode: int, responseBody: string, error: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sentBefore" $sentBefore "scalar") (serialize-qp "sentAfter" $sentAfter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhookId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workflows
#
# GET /workflows
# operationId: listWorkflows
export def "workflows listWorkflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: list # Filter by name
  --ownerId: list # The ID of the workspaces to return resources for
  --workflowID: list # The IDs of the workflows to return resources for
  --environmentId: list # Filter for resources that belong to an environment
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<workflow: record<id: string, name: string, ownerId: string, createdAt: string, updatedAt: string, buildConfig: record, runCommand: string, region: string, environmentId: string, slug: string, autoDeployTrigger: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "csv") (serialize-qp "ownerId" $ownerId "csv") (serialize-qp "workflowID" $workflowID "csv") (serialize-qp "environmentId" $environmentId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workflow
#
# POST /workflows
# operationId: createWorkflow
export def "workflows createWorkflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  ownerId: string
  buildConfig: any
  runCommand: string # The command to run the workflow
  region: string@region-completer # Defaults to "oregon" (default: oregon)
  --autoDeployTrigger: any
  --envVars: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workflows")
  let body = {name: $name, ownerId: $ownerId, buildConfig: $buildConfig, runCommand: $runCommand, region: $region, autoDeployTrigger: $autoDeployTrigger, envVars: $envVars} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve workflow
#
# GET /workflows/{workflowId}
# operationId: getWorkflow
export def "workflows get" [
  workflowId: string
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
  let full_url = (build-url $base $"/workflows/($workflowId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workflow
#
# PATCH /workflows/{workflowId}
# operationId: updateWorkflow
export def "workflows updateWorkflow" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --buildConfig: any
  --runCommand: string # The command to run the workflow
  --autoDeployTrigger: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflows/($workflowId)")
  let body = {name: $name, buildConfig: $buildConfig, runCommand: $runCommand, autoDeployTrigger: $autoDeployTrigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete workflow
#
# DELETE /workflows/{workflowId}
# operationId: deleteWorkflow
export def "workflows delete" [
  workflowId: string
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
  let full_url = (build-url $base $"/workflows/($workflowId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workflow versions
#
# GET /workflowversions
# operationId: listWorkflowVersions
export def "workflowversions listWorkflowVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ownerId: list # The ID of the workspaces to return resources for
  --workflowID: list # The IDs of the workflows to return resources for
  --workflowVersionId: list # The IDs of the workflow versions to return resources for
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<workflowVersion: record<id: string, workflowId: string, name: string, createdAt: string, status: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ownerId" $ownerId "csv") (serialize-qp "workflowID" $workflowID "csv") (serialize-qp "workflowVersionId" $workflowVersionId "csv") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflowversions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deploy a workflow version
#
# POST /workflowversions
# operationId: createWorkflowVersion
export def "workflowversions createWorkflowVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workflowId: string
  --commit: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workflowversions")
  let body = {workflowId: $workflowId, commit: $commit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve workflow version
#
# GET /workflowversions/{workflowVersionId}
# operationId: getWorkflowVersion
export def "workflowversions get" [
  workflowVersionId: string
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
  let full_url = (build-url $base $"/workflowversions/($workflowVersionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tasks
#
# GET /tasks
# operationId: listTasks
export def "tasks listTasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --taskSlug: list # An array of task slugs in the format workflow-slug/task-name. An optional version can be appended (workflow-slug/task-name:version). If no version is provided, the latest version is used. (e.g. [my-workflow-slug/my-task, my-workflow-slug/my-task:SHA123])
  --workflowVersionId: list # An array of workflow version IDs
  --workflowId: list # An array of workflow IDs
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
]: nothing -> table<task: record<id: string, name: string, createdAt: string, workflowId: string, workflowVersionId: string>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskSlug" $taskSlug "multi") (serialize-qp "workflowVersionId" $workflowVersionId "multi") (serialize-qp "workflowId" $workflowId "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve task
#
# GET /tasks/{taskId}
# operationId: getTask
export def "tasks get" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List task runs
#
# GET /task-runs
# operationId: listTaskRuns
export def "task-runs listTaskRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The position in the result list to start from when fetching paginated results. For details, see [Pagination](https://api-docs.render.com/reference/pagination).
  --limit: int # The maximum number of items to return. For details, see [Pagination](https://api-docs.render.com/reference/pagination). (default: 20)
  --rootTaskRunId: list # An array of root task run IDs to filter on
  --ownerId: list # The ID of the workspaces to return resources for
]: nothing -> table<taskRun: record<id: string, taskId: string, status: string, startedAt: string, completedAt: string, parentTaskRunId: string, rootTaskRunId: string, retries: int, attempts: list>, cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "rootTaskRunId" $rootTaskRunId "multi") (serialize-qp "ownerId" $ownerId "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/task-runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run task
#
# POST /task-runs
# operationId: createTask
export def "task-runs createTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  task: string # A task slug in the format workflow-slug/task-name. An optional version can be appended (workflow-slug/task-name:version). If no version is provided, the latest version is used. (e.g. my-workflow-slug/my-task, my-workflow-slug/my-task:SHA123)
  input: any # Input data for a task. Can be either an array (for positional arguments) or an object (for named parameters).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/task-runs")
  let body = {task: $task, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stream realtime events (SSE)
#
# GET /task-runs/events
# operationId: streamTaskRunsEvents
export def "task-runs-events streamTaskRunsEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --taskRunIds: list # Filter to a subset of task run IDs. (e.g. [trn-1234, trn-5678])
  --Accept: string@Accept-completer # Must be `text/event-stream`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskRunIds" $taskRunIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/task-runs/events" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve task run
#
# GET /task-runs/{taskRunId}
# operationId: getTaskRun
export def "task-runs get" [
  taskRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, taskId: string, status: any, results: list<any>, error: string, startedAt: string, completedAt: string, input: any, parentTaskRunId: string, rootTaskRunId: string, retries: int, attempts: table<status: any, enqueuedAt: string, startedAt: string, completedAt: string, error: string, results: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/task-runs/($taskRunId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel task run
#
# DELETE /task-runs/{taskRunId}
# operationId: cancelTaskRun
export def "task-runs cancelTaskRun" [
  taskRunId: string
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
  let full_url = (build-url $base $"/task-runs/($taskRunId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
